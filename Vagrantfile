# -*- mode: ruby -*-

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'libvirt'
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure("2") do |config|
  config.vm.box = "rockylinux/9"
  config.vm.box_check_update = false
  config.vm.synced_folder '.', '/vagrant', disabled: true
  #config.vm.provider :libvirt do |v|
  #  v.memorybacking :access, :mode => "shared"
  #end
  #config.vm.synced_folder "./", "/vagrant", type: "virtiofs"
  #config.vm.network "forwarded_port", guest: 22, host: 22
  config.ssh.forward_agent = true

  # DNS Server
  config.vm.define :dnsserver do |dns|
    dns.vm.hostname = 'dns.oelabox.local'
    dns.vm.network :private_network, ip: "192.168.121.10"

    dns.vm.provider :libvirt do |v|
      v.memory = 512
      v.cpus = 2
    end

    dns.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision-oelabox-dns.yml"
      ansible.inventory_path = "inventory.ini"
    end
  end

  # IPA Server
  config.vm.define :ipaserver do |ipa|
    ipa.vm.hostname = 'ipa.oelabox.local'
    ipa.vm.network :private_network, ip: "192.168.121.11"

    ipa.vm.provider :libvirt do |v|
      v.memory = 4096
      v.cpus = 2
    end

    ipa.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision-oelabox-dns-client.yml"
      ansible.inventory_path = "inventory.ini"
      ansible.extra_vars = { host: "dnsclient" }
    end

    ipa.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision-oelabox-ipa.yml"
      ansible.inventory_path = "inventory.ini"
    end

    ipa.vm.provision "ansible" do |ansible|
      ansible.playbook = "init-oelabox-ipa-team.yml"
      ansible.inventory_path = "inventory.ini"
    end
  end

  # Koji Server
  config.vm.define :kojiserver do |koji|
    koji.vm.box = "centos/stream8"

    koji.vm.hostname = 'koji.oelabox.local'
    koji.vm.network :private_network, ip: "192.168.121.12"

    koji.vm.provider :libvirt do |v|
      v.storage :file, :size => '70G', :device => 'vdb'
      v.memory = 4096
      v.cpus = 2
    end

    # Add IPA builtin DNS server to resolv.conf, so the IPA client can be provisioned
    koji.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision-oelabox-dns-client.yml"
      ansible.inventory_path = "inventory.ini"
      ansible.extra_vars = {
        host: "ipaclient",
        resolv_entries: [
              nameserver: "192.168.121.11",
              search: [ "oelabox.local" ],
        ],
      }
    end

    koji.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision-oelabox-ipa-client.yml"
      ansible.inventory_path = "inventory.ini"
      ansible.extra_vars = { host: "ipaclient" }
    end

    koji.vm.provision "ansible" do |ansible|
      ansible.playbook = "provision-oelabox-koji-builder.yml"
      ansible.inventory_path = "inventory.ini"
    end

    koji.vm.provision "ansible" do |ansible|
      ansible.playbook = "init-oelabox-koji-ecosystem.yml"
      ansible.inventory_path = "inventory.ini"
    end
  end

  config.vm.provision "tools", type: "ansible" do |t|
    t.playbook = "setup-oelabox-tools.yml"
    t.inventory_path = "inventory.ini"
  end
end
