Vagrant.configure(2) do |config|
  config.vm.define "rancheros-test" do |test|
    test.vm.box = "rancheros"

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
        run_remote "sudo system-docker restart ntp && date"
      end
    end

    # Adjusting datetime before provisioning.
    test.vm.provision :shell, run: "always" do |sh|
      sh.privileged = false
      sh.inline = "sudo system-docker restart ntp && date"
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
