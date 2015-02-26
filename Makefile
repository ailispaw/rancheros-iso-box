rancheros-virtualbox.box: rancheros.iso template.json vagrant_plugin_guest_busybox.rb
	packer build template.json

rancheros.iso:
	curl -OL https://github.com/rancherio/os/releases/download/v0.1.1/rancheros.iso

install: rancheros-virtualbox.box
	vagrant box add -f rancheros rancheros-virtualbox.box

boot_test: install
	vagrant destroy -f rancheros-test
	vagrant up rancheros-test --no-provision

clean:
	vagrant destroy -f
	$(RM) rancheros-virtualbox.box
	$(RM) rancheros.iso
	$(RM) -r packer_cache

.PHONY: install boot_test clean
