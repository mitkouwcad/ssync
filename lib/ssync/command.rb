require "ssync"

module Ssync
  class Command
    include Helpers

    def self.action
      @@action
    end

    def self.args
      @@args
    end

    def self.run!(*args)
      new(*args).run!
    end

    def initialize(action = :sync, *args)
      @@action = action.to_sym
      @@args   = args

      if @@args[0] && @@args[0][0, 1] != "-"
        Setup.default_config[:last_used_bucket] = @@args[0]
        write_default_config!(Setup.default_config)
      end
    end

    def run!
      util_check!
      pre_run_check!
      perform_action!
    end

    private

    def util_check!
      %w{find xargs openssl}.each do |util|
        e! "You do not have '#{util}' installed on your operating system." if `which #{util}`.empty?
      end
    end

    def pre_run_check!
      if action_eq?(:sync) && !config_exists?(default_config_path) && !config_exists?
        e! "Cannot run the sync, there is no Ssync configuration, try 'ssync setup' to create one first."
      end
    end

    def perform_action!
      case @@action
      when :setup
        Ssync::Setup.run!
      when :sync
        aquire_lock! { Ssync::Sync.run! }
      when :help, :"--help", :"-h"
        display_help!
      when :version, :"--version", :"-v"
        puts Ssync::VERSION
      else
        e! "Cannot perform action '#{@action}', try 'ssync help' for usage."
      end
    end
  end
end