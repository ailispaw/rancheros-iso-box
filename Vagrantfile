module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "change_host_name") do
        Cap::ChangeHostName
      end

      guest_capability("linux", "configure_networks") do
        Cap::ConfigureNetworks
      end
    end
  end
end

Vagrant.configure(2) do |config|
  config.vm.define "rancheros-test" do |test|
    test.vm.box = "rancheros"
    test.vm.box_url = "file://rancheros-virtualbox.box"

    test.vm.hostname = "rancheros-test"

    test.vm.network "private_network", ip: "192.168.33.10"

    test.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["nolock", "vers=3", "udp"]

    test.vm.provider :virtualbox do |vb|
      vb.name = "rancheros-test"
      vb.gui = true
    end

    if Vagrant.has_plugin?("vagrant-triggers") then
      test.trigger.after [:up, :resume] do
        info "Adjusting datetime after suspend and resume."
        run_remote <<-EOT.prepend("\n")
          sudo system-docker stop ntp
          sudo ntpd -n -q -g -I eth0 > /dev/null
          date
          sudo system-docker start ntp
        EOT
      end
    end

    # Adjusting datetime before provisioning.
    test.vm.provision :shell, run: "always" do |sh|
      sh.inline = <<-EOT
        system-docker stop ntp
        ntpd -n -q -g -I eth0 > /dev/null
        date
        system-docker start ntp
      EOT
    end

    test.vm.provision :docker do |d|
      d.pull_images "yungsang/busybox"
      d.run "simple-echo",
        image: "yungsang/busybox",
        args: "-p 8080:8080",
        cmd: "nc -p 8080 -l -l -e echo hello world!"
    end

    test.vm.network :forwarded_port, guest: 8080, host: 8080
  end
end
