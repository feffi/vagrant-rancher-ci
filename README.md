# Rancher Drone CI/CD Development Environment

Automated local Rancher environments using Vagrant

## Install

```
git clone https://github.com/feffi/vagrant-rancher
cd vagrant-rancher
vagrant up
```

If you used the defaults, browse to [http://10.0.0.11:8080](http://10.0.0.11:8080) to access the installed Rancher server.

## Configuration

You can configure the vagrant environment by customizing `config.rb`. The available configuration options are:

| Item                   | Type     | Required | Default             | Description                                                              |
|------------------------|----------|----------|---------------------|--------------------------------------------------------------------------|
| `$box`                 | *string* | false    | rancherio/rancheros | Vagrant box to use for the environment                                   |
| `$box_url`             | *string* | false    | `nil`               | URL to download the box                                                  |
| `$box_version`         | *string* | false    | `nil`               | Version of the box to download                                           |
| `$disable_folder_sync` | *bool*   | false    | `true`              | Disable syncing the current working directory to "/vagrant" on the guest |
| `$ip_prefix`           | *string* | false    | 192.168.33          | Prefix for all IPs assigned to the guests                                |
| `$rancher_version`     | *string* | false    | latest              | Version of Rancher to deploy                                             |
| `$boxes`               | *array*  | true     | `[]`                | List of boxes (see [Boxes](#boxes) table below)                                  |

### Boxes

| Item            | Type     | Required | Default                                        | Description                                                                           |
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

See [config.rb](config.rb)
