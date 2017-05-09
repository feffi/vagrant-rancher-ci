require 'fileutils'

Vagrant.require_version ">= 1.6.0"

CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), "user-data")
CLOUD_MGMT_CONFIG_PATH = File.join(File.dirname(__FILE__), "mgmt-user-data")
CONFIG = File.join(File.dirname(__FILE__), "config.rb")

# set defaults
$boxes = []
$box = 'rancherio/rancheros'
$box_url = nil
$box_version = nil
$rancher_version = 'latest'
$ip_prefix = '10.0.0'
$disable_folder_sync = true
$proxies = {
  "http" => nil,
  "https" => nil,
  "no_proxy" => nil
}

# read and load the config file
if File.exist?(CONFIG)
    require CONFIG
end

# install the vagrant-rancher provisioner plugin
unless Vagrant.has_plugin?('vagrant-rancher')
  puts 'vagrant-rancher plugin not found, installing...'
  `vagrant plugin install vagrant-rancher`
  abort 'vagrant-rancher plugin installed, but you need to rerun the vagrant command'
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
    if $box == 'rancherio/rancheros'
      if !box['memory'].nil? and box['memory'].to_i < 512
        puts 'WARNING: Running RancherOS on less than 512MB of RAM has been known to cause issues.'
      end
    end
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

# require some capability overrides if the box is rancheros
#if $box == 'rancherio/rancheros'
#  require_relative 'lib/vagrant_rancheros_guest_plugin.rb'
#end

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

  # Try to use a custom CoreOS box
#  if $update_channel != nil
      config.vm.box = "coreos-%s" % $update_channel
      config.vm.box_url = $box_url unless $box_url.nil?
      config.vm.box_version = $box_version unless $box_version.nil?
      config.vm.guest = :linux
#  else
#      # Default to RancherOS
#      config.vm.box = $box
#      config.vm.box_url = $box_url unless $box_url.nil?
#      config.vm.box_version = $box_version unless $box_version.nil?
#      config.vm.guest = :linux
#  end

  if $disable_folder_sync
    config.vm.synced_folder '.', '/vagrant', disabled: true
#  else
#    # if box is rancheros use rsync
#    if $box == 'rancherio/rancheros'
#      config.vm.synced_folder ".", "/vagrant", type: "rsync",
#        rsync__exclude: ".git/",
#        rsync__args: ["--verbose", "--archive", "--delete", "--copy-links"],
#        disabled: false
    else
      config.vm.synced_folder '.', '/vagrant', disabled: false
#    end
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
      hostname = "#{box['name']}-%02d" % i
      config.vm.define hostname do |node|
        node.vm.hostname = hostname
        ip = box['ip'] ? box['ip'] : "#{$ip_prefix}.#{box_index+1}#{i}"
        node.vm.network 'private_network', ip: ip
        unless box['memory'].nil?
          node.vm.provider 'virtualbox' do |vb|
            vb.memory = box['memory']
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
            rancher.project = box['project'] unless box['project'].nil?
            rancher.project_type = box['project_type'] unless box['project_type'].nil?
          end
          config.vm.provision :file, :source => "#{CLOUD_MGMT_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
          config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
        else
          node.vm.provision :rancher do |rancher|
            rancher.role = 'agent'
            rancher.hostname = box['server'] || $default_server_ip
            rancher.install_agent = box['install_agent'] unless box['install_agent'].nil?
            rancher.labels = box['labels'] unless box['labels'].nil?
            rancher.project = box['project'] unless box['project'].nil?
            rancher.project_type = box['project_type'] unless box['project_type'].nil?
          end
          config.vm.provision :file, :source => "#{CLOUD_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
          config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
        end
      end
    end
  end
end
