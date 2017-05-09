# Vagrant box configuration details image of the box to use
$box = "rancherio/rancheros"

# Version of the box image
$box_version = '>= 308.0.1'

# Official CoreOS channel. Either alpha, beta or stable
$update_channel = "alpha"

# URL to pull CoreOS image from
$box_url = "http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json" % $update_channel

# Tag of the rancher/server image to run
 $rancher_version = 'latest'

# IP prefix to use when assigning box ip addresses
$ip_prefix = '10.0.0'

# Enable syncing of the current directory to the /vagrant path on the guest
$disable_folder_sync = false

# Proxy configure on boxes, defaults to none if not defined
#$proxies = {
#  "http" => "http://<ip or url>:<port>/",
#  "https" => "https://<ip or url>:<port>/",
#  "no_proxy" => "localhost,127.0.0.1,<ip or url>"
#}

# Boxes to create in the vagrant environment
$boxes = [
    {
      "name"   => "rancher-server",
      "role"   => "server",
      "memory" => "1536",
      "labels" => [],
    },
    {
      "name"   => "rancher-agent",
      "count"  => 1,
      "memory" => "512",
      "labels" => ["type=general"]
    },
]

$new_discovery_url='https://discovery.etcd.io/new'

if File.exists?('user-data') && ARGV[0].eql?('up')
  require 'open-uri'
  require 'yaml'
 
  token = open($new_discovery_url).read
 
  data = YAML.load(IO.readlines('user-data')[1..-1].join)
  data['coreos']['etcd']['discovery'] = token
 
  yaml = YAML.dump(data)
  File.open('user-data', 'w') { |file| file.write("#cloud-config\n\n#{yaml}") }
 
  data = YAML.load(IO.readlines('mgmt-user-data')[1..-1].join)
  data['coreos']['etcd']['discovery'] = token
 
  yaml = YAML.dump(data)
  File.open('mgmt-user-data', 'w') { |file| file.write("#cloud-config\n\n#{yaml}") }
end