# Add change_host_name guest capability
module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "change_host_name") do
        Cap::ChangeHostName
      end
    end

    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          new(machine, name).change!
        end

        attr_reader :machine, :new_hostname

        def initialize(machine, new_hostname)
          @machine = machine
          @new_hostname = new_hostname
        end

        def change!
          change_hostname_for_console
        end

        def change_hostname_for_console
          machine.communicate.tap do |comm|
            if !comm.test("hostname -s | grep '^#{short_hostname}$'")
              comm.sudo("sh -c 'echo \"#{short_hostname}\" > /etc/hostname'")
              comm.sudo("hostname -F /etc/hostname")
            end
            if (domain != "") && !comm.test("grep '^domain #{domain}$' /etc/resolv.conf")
              comm.sudo("sh -c 'echo \"domain #{domain}\" >> /etc/resolv.conf'")
            end
          end
        end

        def short_hostname
          new_hostname.split('.').first
        end

        def domain
          domain = ""
          if short_hostname != new_hostname
            domain = new_hostname.split('.')[1..-1].join('.')
          end
          domain
        end
      end
    end
  end
end

# Add configure_networks guest capability
require 'ipaddr'

# Borrowing from http://stackoverflow.com/questions/1825928/netmask-to-cidr-in-ruby
IPAddr.class_eval do
  def to_cidr
    self.to_i.to_s(2).count("1")
  end
end

module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "configure_networks") do
        Cap::ConfigureNetworks
      end
    end

    module Cap
      class ConfigureNetworks
        def self.configure_networks(machine, networks)
          machine.communicate.tap do |comm|
            networks.each do |network|
              iface = "eth#{network[:interface]}"
              dhcp  = "true"

              if network[:type] == :static
                cidr = IPAddr.new(network[:netmask]).to_cidr
                comm.sudo("rancherctl config set network.interfaces.#{iface}.address #{network[:ip]}/#{cidr}")
                dhcp = "false"
              end

              comm.sudo("rancherctl config set network.interfaces.#{iface}.dhcp #{dhcp}")
            end

            comm.sudo("system-docker restart network")
          end
        end
      end
    end
  end
end

# Skip checking nfs client, because mount supports nfs.
require Vagrant.source_root.join("plugins/guests/linux/cap/nfs_client.rb")
module VagrantPlugins
  module GuestLinux
    module Cap
      class NFSClient
        def self.nfs_client_installed(machine)
          true
        end
      end
    end
  end
end

# Skip ensure_installed for Docker Provisioner
require Vagrant.source_root.join("plugins/provisioners/docker/installer.rb")
module VagrantPlugins
  module DockerProvisioner
    class Installer
      def ensure_installed
      end
    end
  end
end

# Mount in the userdocker container as well
require Vagrant.source_root.join("plugins/guests/linux/cap/mount_nfs.rb")
module VagrantPlugins
  module GuestLinux
    module Cap
      class MountNFS
        extend Vagrant::Util::Retryable

        def self.mount_nfs_folder(machine, ip, folders)
          folders.each do |name, opts|
            # Expand the guest path so we can handle things like "~/vagrant"
            expanded_guest_path = machine.guest.capability(
              :shell_expand_guest_path, opts[:guestpath])

            # Do the actual creating and mounting
            machine.communicate.sudo("mkdir -p #{expanded_guest_path}")

            # Mount
            hostpath = opts[:hostpath].dup
            hostpath.gsub!("'", "'\\\\''")

            # Figure out any options
            mount_opts = ["vers=#{opts[:nfs_version]}"]
            mount_opts << "udp" if opts[:nfs_udp]
            if opts[:mount_options]
              mount_opts = opts[:mount_options].dup
            end

            mount_command = "mount -o '#{mount_opts.join(",")}' #{ip}:'#{hostpath}' #{expanded_guest_path}"
            retryable(on: Vagrant::Errors::LinuxNFSMountFailed, tries: 8, sleep: 3) do
              machine.communicate.sudo(mount_command,
                                       error_class: Vagrant::Errors::LinuxNFSMountFailed)
            end

            # Do the actual creating and mounting
            machine.communicate.sudo("system-docker exec userdocker mkdir -p #{expanded_guest_path}")

            mount_command = "system-docker exec userdocker mount -o '#{mount_opts.join(",")}' #{ip}:'#{hostpath}' #{expanded_guest_path}"
            retryable(on: Vagrant::Errors::LinuxNFSMountFailed, tries: 8, sleep: 3) do
              machine.communicate.sudo(mount_command,
                                       error_class: Vagrant::Errors::LinuxNFSMountFailed)
            end

            # Emit an upstart event if we can
            if machine.communicate.test("test -x /sbin/initctl")
              machine.communicate.sudo(
                "/sbin/initctl emit --no-wait vagrant-mounted MOUNTPOINT=#{expanded_guest_path}")
            end
          end
        end
      end
    end
  end
end
