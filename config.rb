# Official CoreOS channel. Either alpha, beta or stable
$update_channel = "alpha"

# Vagrant box configuration details image of the os to use
$os = "coreos-%s" % $update_channel

# Version of the box image
$os_version = '>= 1548.0.0'

# URL to pull CoreOS image from
$os_url = "http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json" % $update_channel

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
#    {
#      "name"   => "rancher-agent",
#      "count"  => 4,
#      "memory" => "512",
#      "labels" => []
#    },
    {
      "name"   => "k8s-nodes",
      "count"  => 4,
      "memory" => "512",
      "labels" => [],
#      "project" => "k8s",
#      "project_type" => "kubernetes"
    },
]
