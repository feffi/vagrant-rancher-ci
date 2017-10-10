# The OS to use (here coreos alpha)
$os = {
  # Vagrant box configuration details image of the os to use
  "vm" => "coreos-alpha",

  # Version of the box image
  "version" => '>= 1548.0.0',

  # URL to pull OS image from
  "url" => "http://alpha.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json"
}

# Tag of the rancher/server image to run
$rancher = {
  "version" => 'v2.0.0-alpha10'
}

# IP prefix to use when assigning box ip addresses
$ipPrefix = '10.2.0'

# Enable syncing of the current directory to the /vagrant path on the guest
$folderSync = false

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
    "user"   => "admin",
    "kind"   => "admin"
  },
  {
    "name"   => "k8s-node",
    "count"  => 4,
    "memory" => "1024",
    "labels" => []
  },
]
