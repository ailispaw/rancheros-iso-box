require_relative "vagrant_plugin_guest_rancheros.rb"

Vagrant.configure("2") do |config|
  config.ssh.username = "rancher"

  # Forward the Docker port
  config.vm.network :forwarded_port, guest: 2375, host: 2375

  # Disable synced folder by default
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider :virtualbox do |vb|
    vb.check_guest_additions = false
    vb.functional_vboxsf     = false

    vb.customize "pre-boot", [
      "storageattach", :id,
      "--storagectl", "SATA Controller",
      "--port", "1",
      "--device", "0",
      "--type", "dvddrive",
      "--medium", File.expand_path("../rancheros.iso", __FILE__),
    ]
  end
end
