rancheros-virtualbox.box: rancheros.iso template.json vagrant_plugin_guest_busybox.rb \
	oem/start.sh oem/rancher.yml oem/install.sh
	packer build template.json

rancheros.iso:
	curl -OL https://github.com/rancherio/os/releases/download/v0.2.1/rancheros.iso

install: rancheros-virtualbox.box
	vagrant box add -f rancheros rancheros-virtualbox.box

boot_test: install
	vagrant destroy -f
	vagrant up --no-provision

test: boot_test
	vagrant provision
	@echo "-----> docker version"
	docker version
	@echo "-----> docker images -t"
	docker images -t
	@echo "-----> docker ps -a"
	docker ps -a
	@echo "-----> nc localhost 8080"
	@nc localhost 8080
	@echo "-----> hostname"
	@vagrant ssh -c "hostname" -- -T
	@echo "-----> route"
	@vagrant ssh -c "route" -- -T
	vagrant suspend

clean:
	vagrant destroy -f
	$(RM) rancheros-virtualbox.box
	$(RM) rancheros.iso
	$(RM) -r .vagrant
	$(RM) -r .certs
	$(RM) -r packer_cache

.PHONY: install boot_test clean
