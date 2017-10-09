require 'fileutils'

Vagrant.require_version ">= 1.9.4"

# set defaults
$boxes = []
$update_channel = "alpha"
$os = "coreos-%s" % $update_channel
$os_version = '>= 1548.0.0'
$os_url = "http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json" % $update_channel
$rancher_version = 'v2.0.0-alpha10'
$ip_prefix = '10.2.0'
$folder_sync = true
$proxies = {
  "http" => nil,
  "https" => nil,
  "no_proxy" => nil
}

# read and load the config file
CONFIG = File.join(File.dirname(__FILE__), "config.rb")
if File.exist?(CONFIG)
    require CONFIG
end

# install the vagrant-rancher provisioner plugin
unless Vagrant.has_plugin?('vagrant-rancher-v3')
  puts 'vagrant-rancher-v3 provisioner plugin not found, installing...'
  #`vagrant plugin install vagrant-rancher`
  `vagrant plugin install ./vagrant-rancher/pkg/vagrant-rancher-v3-1.0.0.gem`
  abort 'vagrant-rancher-v3 provisioner plugin installed, but you need to rerun the vagrant command'
end

unless Vagrant.has_plugin?('vagrant-proxyconf')
  puts 'vagrant-proxyconf plugin not found, installing...'
  `vagrant plugin install vagrant-proxyconf`
  abort 'vagrant-proxyconf plugin installed, but you need to rerun the vagrant command'
end

# validate existance of rancher server
def parse_boxes(boxes)
  servers = []
  agents = []
  boxes.each do |box|
    abort 'Must specify name for box' if box['name'].nil?
    if !box['role'].nil? and box['role'] == 'server'
      servers.push(box)
    else
      agents.push(box)
    end
  end
  abort 'At least one server must be specified in the $boxes config' if servers.empty?
  return servers + agents
end

# loop boxes to get ip address of the first server box found
def get_server_ip(boxes, hostname='')
  default_server_ip = nil
  boxes.each_with_index do |box, i|
    if not box['role'].nil? and box['role'] == 'server'
      ip = box['ip'] ? box['ip'] : "#{$ip_prefix}.#{i+1}#{i+1}"
      default_server_ip = ip if default_server_ip.nil?
      if hostname == "#{box['name']}-%02d" % i
        return ip
      end
    end
  end
  return default_server_ip
end

# sort boxes
$sorted_boxes = parse_boxes $boxes

# determine server ip
$default_server_ip = get_server_ip $sorted_boxes

Vagrant.configure(2) do |config|

  # global config
  config.ssh.insert_key = false

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  # On VirtualBox, we don't have guest additions or a functional vboxsf in CoreOS, so tell Vagrant that so it can be smarter.
  config.vm.provider :virtualbox do |v|
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  config.vm.box = $os
  config.vm.box_url = $os_url unless $os_url.nil?
  config.vm.box_version = $os_version unless $os_version.nil?
  config.vm.guest = :coreos

  config.vm.synced_folder '.', '/vagrant', disabled: true
  if $folder_sync
    config.vm.synced_folder '.', '/vagrant', disabled: false
  end

  # Set correct proxies if defined, defaults to none
  if Vagrant.has_plugin?("vagrant-proxyconf")

    unless $proxies['http'].nil?
      config.proxy.http = $proxies['http']
    end
    unless $proxies['https'].nil?
      config.proxy.https = $proxies['https']
    end
    unless $proxies['ftp'].nil?
      config.proxy.ftp = $proxies['ftp']
    end
    unless $proxies['no_proxy'].nil?
      config.proxy.no_proxy = $proxies['no_proxy']

      # Determine box ips for private networking
      $sorted_boxes.each_with_index do |box, box_index|
        count = box['count'] || 1

        # loop instances of agents
        (0..count).each do |i|
          ip = box['ip'] ? box['ip'] : "#{$ip_prefix}.#{box_index+1}#{i}"
          config.proxy.no_proxy = config.proxy.no_proxy + "," + ip
        end
      end
    end
  end

  $sorted_boxes.each_with_index do |box, box_index|
    count = box['count'] || 1

    # loop instances
    (1..count).each do |i|
      # configure network
      hostname = "#{box['name']}-%02d" % i
      config.vm.define hostname do |node|
        node.vm.hostname = hostname
        ip = box['ip'] ? box['ip'] : "#{$ip_prefix}.#{box_index+1}#{i}"
        node.vm.network 'private_network', ip: ip

        # configure hardware
        unless box['memory'].nil?
          node.vm.provider 'virtualbox' do |vb|
            vb.memory = box['memory']
            vb.customize ["modifyvm", :id, "--vram", "2"]
            vb.customize ["modifyvm", :id, "--cpuhotplug", "on"]
            vb.customize ["modifyvm", :id, "--ioapic", "on"]
            vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
            vb.customize ["modifyvm", :id, "--boot1", "disk"]
            vb.customize ["modifyvm", :id, "--boot2", "none"]
            vb.customize ["modifyvm", :id, "--boot3", "none"]
            vb.customize ["modifyvm", :id, "--boot4", "none"]
            vb.customize ["storageattach", :id, "--storagectl", "IDE Controller", '--port', '0', '--device', '0', '--nonrotational', 'on']
          end
        end

        if !box['role'].nil? and box['role'] == 'server'
          node.vm.provision :rancher do |rancher|
            rancher.role = 'server'
            rancher.hostname = ip
            rancher.version = $rancher_version
            rancher.deactivate = true
            rancher.install_agent = box['install_agent'] || false
            rancher.labels = box['labels'] unless box['labels'].nil?
            #rancher.project = box['project'] unless box['project'].nil?
            #rancher.project_type = box['project_type'] unless box['project_type'].nil?
          end
        else
          node.vm.provision :rancher do |rancher|
            rancher.role = 'agent'
            rancher.hostname = box['server'] || $default_server_ip
            rancher.install_agent = box['install_agent'] unless box['install_agent'].nil?
            rancher.labels = box['labels'] unless box['labels'].nil?
            #rancher.project = box['project'] unless box['project'].nil?
            #rancher.project_type = box['project_type'] unless box['project_type'].nil?
          end
        end
      end
    end
  end
end
