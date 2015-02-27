# Vagrant Box with RancherOS ISO

Packaging a Vagrant box for [RancherOS](https://github.com/rancherio/os) with the original [RancherOS ISO](https://github.com/rancherio/os/releases)

## Packaging

### Requirements

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