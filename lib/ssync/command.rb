require "ssync"
require "thor"

module Ssync
  class Command < ::Thor
    include Helpers

    default_task :sync

    desc "setup", "Sets up a configuration file for syncing"
    method_option "bucket", :aliases => "-b", :type => :string,
      :banner => "The S3 bucket (configurated with Ssync) to sync to"
    def setup
      %w{find xargs openssl}.each do |util|
        e! "You do not have '#{util}' installed on your operating system." if `which #{util}`.empty?
      end

      if options.bucket?
        e! "The S3 bucket config for '#{options.bucket}' does not exist." unless config_exists?(config_path(options.bucket))
        write_default_config(options.bucket)
      end
      aquire_lock! { Ssync::Setup.run! }
    end

    desc "sync", "Syncs to Amazon S3"
    method_option "bucket", :aliases => "-b", :type => :string,
      :banner => "The S3 bucket (configurated with Ssync) to sync to"
    method_option "force", :aliases => "-f", :type => :boolean,
      :banner => "Forces a recalculate of the checksum, useful when the previous sync was incomplete or corrupted"
    def sync
      unless config_exists?(default_config_path) || config_exists?
        e! "Cannot run the sync, there is no Ssync configuration, try 'ssync setup' to create one first."
      end

      write_default_config(options.bucket) if options.bucket?
      aquire_lock! { Ssync::Sync.run!(options) }
    end

    desc "version", "Prints Ssync's version information"
    def version
      puts "Ssync #{Ssync::VERSION}"
    end
    map %w{-v --version} => :version

    private

    def write_default_config(bucket)
      Setup.default_config[:last_used_bucket] = bucket
      write_default_config!(Setup.default_config)
    end
  end
end