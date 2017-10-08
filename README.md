# Rancher Drone CI/CD Development Environment

Automated local Rancher environments using Vagrant

## Install

```
git clone https://github.com/feffi/vagrant-rancher-ci.git
cd vagrant-rancher-ci
vagrant up
```

If you used the defaults, browse to [http://10.0.0.11:8080](http://10.0.0.11:8080) to access the installed Rancher server.

## Configuration

You can configure the vagrant environment by customizing `config.rb`. The available configuration options are:

| Item                   | Type     | Required | Default        | Description                                                        |
|------------------------|----------|----------|----------------|--------------------------------------------------------------------|
| `$os`                  | *string* | false    | `coreos-alpha` | Vagrant box to use for the environment                             |
| `$os_url`              | *string* | false    | [Link](http://alpha.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json)               | URL to download the box                                                  |
| `$os_version`          | *string* | false    | `>= 1548.0.0`   | Version of the box to download                                     |
| `$disable_folder_sync` | *bool*   | false    | `true`         | Disable syncing the current working directory to "/vagrant" on the guest |
| `$ip_prefix`           | *string* | false    | 10.0.0         | Prefix for all IPs assigned to the guests                          |
| `$rancher_version`     | *string* | false    | `latest`       | Version of Rancher to deploy                                       |
| `$proxies`             | *array*  | false    | `[]`           | Proxies to set in boxes (see [Proxies](#proxies) table below)      |
| `$boxes`               | *array*  | true     | `[]`           | List of boxes (see [Boxes](#boxes) table below)                    |

### Proxies

| Item                   | Type     | Required | Default        | Description                                                        |
|------------------------|----------|----------|----------------|--------------------------------------------------------------------|
| `http`          | *string* | false    | `nil`     | URL or IP of the proxy to use                        |
| `https`         | *string* | false    | `nil`     | URL or IP of the proxy to use                        |
| `no_proxy`      | *string* | false    | `nil`     | URLs or IPs of the proxy exclusions, comma separated |


### Boxes

| Item            | Type     | Required | Default                       | Description                |
|-----------------|----------|----------|------------------------------------------------|---------------------------------------------------------------------------------------|
| `name`          | *string* | true     |                                                | Base name of the box                                                                  |
| `count`         | *string* | false    | 1                                              | Number of guests to create with this config                                           |
| `role`          | *string* | false    | agent                                          | Role of the box (either "server" or "agent", at least one "server" must be specified) |
| `memory`        | *string* | false    | 512                                            | Amount of memory to dedicate to the box (for RancherOS, at least 512 is recommended)  |
| `ip`            | *string* | false    | <computed>                                     | IP address to assign to the box (typically best to leave this alone)                  |
| `install_agent` | *bool*   | false    | `true` if role==agent, `false` if role==server | Whether or not to run the Rancher agent on the guest                                  |
| `project`       | *string* | false    | `nil`                                          | Name of the Rancher project or environment to place the box in                        |
| `project_type`  | *string* | false    | cattle                                         | Type of project to for the Rancher environment (cattle, swarm, kubernetes)            |
| `server`        | *string* | false    | <computed>                                     | Hostname or IP address of the Rancher server to join                                  |

## Example

See [config.rb](config.rb) or use:
```
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
    {
      "name"   => "rancher-nodes",
      "count"  => 4,
      "memory" => "512",
      "labels" => []
    },
    {
      "name"   => "k8s-nodes",
      "count"  => 4,
      "memory" => "512",
      "labels" => [],
      "project" => "k8s",
      "project_type" => "kubernetes"
    },
]
```
