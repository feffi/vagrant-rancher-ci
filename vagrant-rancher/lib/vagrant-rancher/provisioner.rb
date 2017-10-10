require_relative 'rancher'
require_relative 'errors'

module VagrantPlugins
  module Rancher
    class Provisioner < Vagrant.plugin('2', :provisioner)
      def initialize(machine, config, rancher = nil)
        super(machine, config)
        @rancher = rancher || RancherClient.new(@config.hostname, @config.port)
        # TODO: Routen hier eintragen
        # @routeDelete = "..."
      end

      def provision
        @machine.ui.info "Provisioning #{@machine.name} (#{@machine.id})"
        self.checkDocker
        self.installServer if config.role == 'server'
        self.configureServer
        if config.agent
          self.installAgent
          #self.configureAgent
        end
        @machine.ui.info "Provisioning of #{@machine.name} (#{@machine.id}) done"
      end

      # determines if we can reach the docker daemon
      def checkDocker
        @machine.ui.info "Checking communication to docker daemon"
        unless @machine.communicate.test('sh -c sleep 3; sudo docker info')
          @machine.ui.error 'Could not connect to docker daemon'
          raise Errors::DockerConnection
        end
        @machine.ui.detail "Communication successful"
      end

      # installs the rancher server at the supplied version
      def installServer
        @machine.ui.info "Installing rancher server instance"
        @machine.ui.detail "Check for running rancher server container"
        # check to see if the rancher server is already running
        unless @machine.communicate.test('sudo docker inspect rancher-server')
          @machine.ui.detail "Rancher server container not running"
          # pull rancher server image if its not already there
          image = "#{@config.rancherServerImage}:#{@config.version}"
          imageCheckCmd = "sudo docker images | awk '{ print $1\":\"$2 }' | grep -q #{image}"
          unless @machine.communicate.test(imageCheckCmd)
            @machine.ui.detail "Pulling Rancher server image: #{image}..."
            unless @machine.communicate.sudo("docker pull #{image}")
              @machine.ui.error "Could not pull Rancher server image"
              raise Errors::RancherServerContainer
            end
          end

          dockerCmd = "docker run -d --restart=always --name rancher-server -p #{@config.port}:8080"
          # add any user supplied args to the docker command
          unless config.args.nil?
            dockerCmd = "#{dockerCmd} #{config.args}"
          end

          @machine.ui.detail "Starting server container: #{image}..."
          unless @machine.communicate.sudo("#{dockerCmd} #{image}")
            @machine.ui.error 'Could not start Rancher server container'
            raise Errors::RancherServerContainer
          end

          @machine.ui.detail 'Waiting for rancher server API to become available...'
          unless @rancher.waitForApi
            raise Errors::ApiConnectionTimeout,
              :host => @config.hostname,
              :port => @config.port
          end
          # gratuitous pause for the server api
          sleep 5
        end
        @machine.ui.detail "Rancher server container running on http://#{@config.hostname}:#{@config.port}"
      end

      # configures a running server with the required settings
      def configureServer
        @machine.ui.info "Configuring rancher server instance"
        id = @rancher.getClusterIdByName @config.project
        @machine.ui.detail "Using cluster id '#{id}' for project '#{@config.project}'"
        @machine.ui.detail "Setting registration host to http://#{@config.hostname}:#{@config.port}"
        @rancher.configureSetting 'api.host', "http://#{@config.hostname}:#{@config.port}"
        @machine.ui.detail "Determining registration token for cluster '#{id}'"
        registrationToken = @rancher.getRegistrationToken id
        raise Errors::RegistrationTokenMissing unless registrationToken
        @machine.ui.detail "Got registration token for rancher agents"
        @machine.ui.detail "-> #{registrationToken['registrationUrl']}"
      end

      # runs the agent container on the guest
      def installAgent
        @machine.ui.info "Installing rancher agent"
        # if the agent container is not running, start it
        @machine.ui.detail "Check for running rancher agent container"
        unless @machine.communicate.test('sudo docker inspect rancher-agent')
          projectId = @rancher.getProjectId @config.project
          clusterId = @rancher.getClusterIdByName @config.project
          raise Errors::ProjectNotFound if projectId.nil?
          @machine.ui.detail "Using project '#{@config.project}' with id '#{projectId}' with cluster '#{clusterId}'"

          @machine.ui.detail "Retrieving agent registration command for cluster '#{clusterId}'"
          registrationToken = @rancher.getRegistrationToken clusterId

          raise Errors::RegistrationTokenMissing if registrationToken.nil?
          dockerCmd = registrationToken['hostCommand']

          # apply a default label with the machine id used for
          # checking that the agent has indeed registered the host
          labels = "id=#{@machine.id}"
          # apply and additional host labels
          unless config.labels.nil?
            labels = "#{labels}&#{config.labels.join('&')}"
          end
          extra_args = "-e 'CATTLE_HOST_LABELS=#{labels}' --name rancher-agent-bootstrap"
          dockerCmd = dockerCmd.sub('docker run', "docker run #{extra_args}")

          imageCheckCmd = "sudo docker images | awk '{ print $1\":\"$2 }' | grep -q #{registrationToken['image']}"
          unless @machine.communicate.test(imageCheckCmd)
            @machine.ui.info "Pulling Rancher agent image: #{registrationToken['image']}..."
            unless @machine.communicate.sudo("docker pull #{registrationToken['image']}")
              @machine.ui.error "Could not pull Rancher agent image"
              raise Errors::RancherServerContainer
            end
          end

          # start the agent container
          @machine.ui.info "Starting agent container: #{registrationToken['image']}..."
          unless @machine.communicate.sudo(dockerCmd)
            @machine.ui.error "Could not start Rancher agent container"
            raise Errors::RancherAgentContainer
          end

          # wait for the agent to register the host in rancher (checks
          # for the @machine.id in the host labels)
          @machine.ui.detail "Waiting for agent to register '#{@config.project}' with id '#{projectId}' on machine '#{@machine.id}'"
          unless @rancher.waitForAgent projectId, @machine.id
            raise Errors::AgentRegistrationTimeout,
              :host => @config.hostname,
              :port => @config.port
          end
        end
        @machine.ui.detail "Rancher agent container running on http://#{@config.hostname}:#{@config.port}"
      end
    end
  end
end
