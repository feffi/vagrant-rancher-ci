require 'net/http'
require 'json'

module VagrantPlugins
  module Rancher
    class RancherClient
      def initialize(hostname, port)
        @hostname = hostname
        @port = port
      end

      # waits for the rancher api to come online
      def waitForApi(path = '')
        uri = URI "http://#{@hostname}:#{@port}/v3#{path}"
        15.times do |i|
          begin
            Net::HTTP.get_response uri
            break
          rescue
            return false if i == 15
            sleep 10
          end
        end
        true
      end

      # waits for the agent to register the host
      def waitForAgent(projectId, machineId)
        15.times do |i|
          host = self.getHost projectId, machineId
          break unless host.nil?
          return false if i == 15
          sleep 10
        end
        true
      end

      # retrieves and returns a project object
      def getProjectById(id)
        return self.api "/v3/projects/#{id}"
      end

      # retrieves and returns a project object
      def getProjectByName(name = "System")
        id = self.getProjectId(name)
        return self.getProjectById(id)
      end

      # retrieves the project id
      def getProjectId(name = "System")
        id = nil
        response = self.api '/v3/projects'
        unless response.nil? or response['data'].empty?
          response['data'].each do |project|
            if project['name'] == name
              return project['id']
            end
          end
        end
        return nil
      end

      # retrieves the clusterId for a project
      def getClusterIdByName(name = "System")
        project = getProjectByName(name)
        return project['clusterId']
      end

      # retrieves and returns the id of the admin user
      def getUserId(name = "admin", kind = "admin")
        response = self.api '/v3/accounts?name=#{name}&kind=#{kind}'
        return response['data'][0]['id']
      end

      # retrieves a rancher host object
      def getHost(projectId, machineId)
        host = nil
        response = self.api "/v3/projects/#{projectId}/hosts"

        #STDERR.puts response.inspect


        unless response.nil? or response['data'].empty?
          response['data'].each do |h|
            host = h if h['labels'].values.include? machineId
          end
        end
        host
      end

      # retrieves a registration token for a project
      def getRegistrationToken(clusterId)
        response = self.api "/v3/clusters/#{clusterId}"
        return response['registrationToken'] unless response['registrationToken'].nil?
        nil

        #headers = { 'x-api-project-id' => projectId }
        #response = self.api '/v3/registrationtokens/', 'GET', headers

        #return response['data'][0] unless response['data'].empty?
        #nil
      end

      # creates a new project
      def createProject(name, clusterId)
        data = {
          'name'       => name,
          'publicDns'  => false,
          'members'    => [],
          'clusterId'  => clusterId
        }
        return self.api '/v3/project/', 'POST', nil, data
      end

      # sets the default project for a user
      def setDefaultProject(userId, projectId)
        response = self.api "/v3/userpreferences?accountId=#{userId}&name=defaultProjectId"

        data = {
          'name'      => 'defaultProjectId',
          'value'     => projectId,
          'kind'      => 'userPreference',
          'type'      => 'userPreference',
          'accountId' => user_id,
        }

        if response['data'].empty?
          self.api '/v3/userpreferences/', 'POST', nil, data
        else
          preferenceId = response['data'][0]['id']
          self.api "/v3/userpreferences/#{preferenceId}/?action=update", 'POST', nil, data
        end
      end

      # deletes a project
      def deleteProject(projectId)
        self.api "/v3/projects/#{projectId}/?action=delete", 'POST'
        sleep 2
        self.api "/v3/projects/#{projectId}/?action=purge", 'POST'
      end

      # creates a registration token for a project
      def createRegistrationToken(projectId)
        headers = { 'x-api-project-id' => projectId }
        self.api '/v3/registrationtokens/', 'POST', headers
      end

      # configures rancher settings
      def configureSetting(setting, value)
        self.api "/v3/settings/#{setting}", 'PUT', nil, 'value' => value
      end

      # deactivates a host in rancher to avoid being scheduled on
      def deactivateHost(projectId, hostId)
        headers = { 'x-api-project-id' => projectId }
        self.api "/v3/projects/#{projectId}/hosts/#{hostId}/?action=deactivate", 'POST', headers
      end

      protected

      def api(path, type = 'GET', headers = nil, data = nil)
        # define the connection uri to the rancher server
        uri = URI("http://#{@hostname}:#{@port}#{path}")

        # cheap throttle to avoid connection errors due
        # to too many requests in a short time
        sleep 0.1

        unless self.waitForApi path
            raise Errors::ApiConnectionTimeout,
              :host => @config.hostname,
              :port => @config.port
          end
        # attempt to start the http connection
        begin
          Net::HTTP.start(uri.host, uri.port) do |http|
            case type
            when 'GET'
              request = Net::HTTP::Get.new uri.request_uri
            when 'POST'
              request = Net::HTTP::Post.new uri.request_uri
              request['Accept'] = 'application/json'
              request['Content-Type'] = 'application/json'
              data = {} if data.nil?
            when 'PUT'
              request = Net::HTTP::Put.new uri.request_uri
              request['Accept'] = 'application/json'
              request['Content-Type'] = 'application/json'
              data = {} if data.nil?
            end

            # set any supplied headers
            unless headers.nil?
              headers.each do |key, value|
                request.add_field key, value
              end
            end

            # set data for the request
            unless data.nil?
              request.set_form_data data
            end

            # make the request
            response = http.request request

            # if the response code is not 2xx, then errror
            unless response.code =~ /20[0-9]/
              raise Errors::HttpResponseCode,
                :method => type,
                :host => @hostname,
                :port => @port,
                :path => path,
                :code => response.code,
                :error => response.body
            end

            # parse the JSON response and return an object
            return JSON.parse response.body
          end
        rescue Exception => e
          raise Errors::ApiConnectionError,
            :host => @hostname,
            :port => @port,
            :error => e.message
        end
      end
    end
  end
end
