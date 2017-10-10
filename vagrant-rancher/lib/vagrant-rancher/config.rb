module VagrantPlugins
  module Rancher
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :role
      attr_accessor :version
      attr_accessor :hostname
      attr_accessor :port
      attr_accessor :deactivate
      attr_accessor :rancherServerImage
      attr_accessor :args
      attr_accessor :agent
      attr_accessor :labels
      attr_accessor :project

      def initialize
        @role = UNSET_VALUE
        @version = UNSET_VALUE
        @hostname = UNSET_VALUE
        @port = UNSET_VALUE
        @rancherServerImage = UNSET_VALUE
        @args = UNSET_VALUE
        @agent = UNSET_VALUE
        @labels = UNSET_VALUE
        @deactivate = UNSET_VALUE
        @project = UNSET_VALUE
        @project_type = UNSET_VALUE
      end

      def finalize!
        @role = 'server' if @role == UNSET_VALUE
        @version = 'v2.0.0-alpha10' if @version == UNSET_VALUE
        @hostname = nil if @hostname == UNSET_VALUE
        @port = 8080 if @port == UNSET_VALUE
        @rancherServerImage = 'rancher/server' if @rancherServerImage == UNSET_VALUE
        @args = nil if @args == UNSET_VALUE
        @agent = true if @agent == UNSET_VALUE
        @labels = nil if @labels == UNSET_VALUE
        @deactivate = false if @deactivate == UNSET_VALUE
        @project = 'System' if @project == UNSET_VALUE
      end

      def validate(_machine)
        errors = _detected_errors

        unless role == 'server' || role == 'agent'
          errors << ':rancher provisioner requires "role" to either be "server" or "agent"'
        end

        unless version.is_a?(String) || version.nil?
          errors << ':rancher provisioner requires "version" to be a string'
        end

        unless hostname.is_a?(String)
          errors << ':rancher provisioner requires "hostname" to be set to a string'
        end

        unless port.is_a?(Fixnum) || port.is_a?(Fixnum)
          errors << ':rancher provisioner requires "port" to be a number'
        end

        unless rancherServerImage.is_a?(String) || rancherServerImage.nil?
          errors << ':rancher provisioner requires "rancherServerImage" to be a string'
        end

        unless args.is_a?(String) || args.nil?
          errors << ':rancher provisioner requires "args" to be a string'
        end

        unless agent.is_a?(TrueClass) || agent.is_a?(FalseClass)
          errors << ':rancher provisioner requires "agent" to be a bool'
        end

        unless labels.is_a?(Array) || labels.nil?
          errors << ':rancher provisioner requires "labels" to be an array'
        end

        unless deactivate.is_a?(TrueClass) || deactivate.is_a?(FalseClass)
          errors << ':rancher provisioner requires "deactivate" to be a bool'
        end

        { 'rancher provisioner' => errors }
      end
    end
  end
end
