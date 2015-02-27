# Vagrant Box with RancherOS ISO

Packaging a Vagrant box for [RancherOS](https://github.com/rancherio/os) with the original [RancherOS ISO](https://github.com/rancherio/os/releases)

## Packaging

### Requirements

- [VirtualBox](https://www.virtualbox.org/)
- [Packer](https://packer.io/)
- [RancherOS ISO](https://github.com/rancherio/os/releases)

### Build a box

```
$ git clone https://github.com/ailispaw/rancheros-iso-box.git
$ cd rancheros-iso-box
$ packer build template.json
```

Or

```
$ git clone https://github.com/ailispaw/rancheros-iso-box.git
$ cd rancheros-iso-box
$ make
```

## Testing

### Requirements

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- [Talk2Docker](https://github.com/ailispaw/talk2docker)

### Test a box

```
$ vagrant box add -f rancheros rancheros-virtualbox.box
$ vagrant up
$ mkdir -p .certs
$ vagrant ssh -c 'cp /home/rancher/.certs/* /vagrant/.certs/' -- -T
$ talk2docker --config=talk2docker.yml version
```

Or

```
$ make test
```

## Sample Vagrantfile

```ruby
Vagrant.configure(2) do |config|
  config.vm.define "rancheros"

  config.vm.box = "rancheros"
  config.vm.box_url = "https://github.com/ailispaw/rancheros-iso-box/releases/download/v0.3.0/rancheros-virtualbox.box"

  config.vm.hostname = "rancheros"

  config.vm.network "private_network", ip: "192.168.33.10"

  config.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["nolock", "vers=3", "udp"]

  if Vagrant.has_plugin?("vagrant-triggers") then
    config.trigger.after [:up, :resume] do
      info "Adjusting datetime after suspend and resume."
      run_remote <<-EOT.prepend("\n")
        sudo system-docker stop ntp
        sudo ntpd -n -q -g
        date
        sudo system-docker start ntp
      EOT
    end
  end

  # Adjusting datetime before provisioning.
  config.vm.provision :shell, run: "always" do |sh|
    sh.inline = <<-EOT
      system-docker stop ntp
      ntpd -n -q -g
      date
      system-docker start ntp
    EOT
  end
end
```