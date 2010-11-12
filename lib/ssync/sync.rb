module Ssync
  class Sync
    class << self
      include Helpers

      def run!
        display "Initialising Ssync, performing pre-sync checks ..."

        e! "Couldn't connect to AWS with the credentials specified in '#{config_path}'." unless Setup.aws_credentials_is_valid?
        e! "Couldn't find the S3 bucket specified in '#{config_path}'." unless Setup.bucket_exists?
        e! "The local path specified in '#{config_path}' does not exist." unless Setup.local_file_path_exists?

        if options_set?("-f", "--force")
          display "Clearing previous sync state ..."
          clear_sync_state
        end
        create_tmp_sync_state

        if last_sync_recorded?
          display "Performing time based comparison ..."
          files_modified_since_last_sync
        else
          display "Performing (potentially expensive) MD5 checksum comparison ..."
          display "Generating local manifest ..."
          generate_local_manifest
          display "Traversing S3 for remote manifest ..."
          fetch_remote_manifest
          # note that we do not remove files on s3 that no longer exist on local host.
          # this behaviour may be desirable (ala rsync --delete) but we currently don't support it.
          display "Performing checksum comparison ..."
          files_on_localhost_with_checksums - files_on_s3
        end.each { |file| push_file(file) }

        finalize_sync_state

        display "Sync complete!"
      end

      def clear_sync_state
        `rm -f #{last_sync_started} #{last_sync_completed}`
      end

      def create_tmp_sync_state
        `touch #{last_sync_started}`
      end

      def last_sync_started
        ENV['HOME'] + "/#{ssync_filename}.last-sync.started"
      end

      def last_sync_completed
        ENV['HOME'] + "/#{ssync_filename}.last-sync.completed"
      end

      def last_sync_recorded?
        File.exist?(last_sync_completed)
      end

      def finalize_sync_state
        `cp #{last_sync_started} #{last_sync_completed}`
      end

      def files_modified_since_last_sync
        # '! -type d' ignores directories, in local manifest directories are spit out to stderr whereas directories pop up in this query
        `find #{read_config[:local_file_path]} #{read_config[:find_options]} \! -type d -cnewer #{last_sync_completed}`.split("\n").collect { |path| { :path => path } }
      end

      def update_config_with_sync_state(sync_start)
        config = read_config()
        config[:last_sync_at] = sync_start
        write_config!(config)
      end

      def generate_local_manifest
        `find #{read_config[:local_file_path]} #{read_config[:find_options]} -print0 | xargs -0 openssl md5 2> /dev/null > #{local_manifest_path}`
      end

      def fetch_remote_manifest
        @remote_objects_cache = []
        traverse_s3_for_objects(AWS::S3::Bucket.find(read_config[:aws_dest_bucket]), @remote_objects_cache)
      end

      def traverse_s3_for_objects(bucket, collection, n = 1000, upto = 0, marker = nil)
        objects = bucket.objects(:marker => marker, :max_keys => n)
        if objects.size == 0
          return
        else
          objects.each { |object| collection << { :path => "/#{object.key}", :checksum => object.etag } }
          traverse_s3_for_objects(bucket, collection, n, upto+n, objects.last.key)
        end
      end

      def files_on_localhost_with_checksums
        parse_manifest(local_manifest_path)
      end

      def files_on_s3
        @remote_objects_cache
      end

      def local_manifest_path
        "/tmp/#{ssync_filename}.manifest.local"
      end

      def parse_manifest(location)
        []
        open(location, "r") do |file|
          file.collect do |line|
            path, checksum = *line.chomp.match(/^MD5\((.*)\)= (.*)$/).captures
            { :path => path, :checksum => checksum }
          end
        end if File.exist?(location)
      end

      def push_file(file)
        # xfer speed, logging, etc can occur in this method
        display "Pushing '#{file[:path]}' ..."
        AWS::S3::S3Object.store(file[:path], open(file[:path]), read_config[:aws_dest_bucket])
      rescue
        e "Could not push '#{file[:path]}': #{$!.inspect}"
      end
    end
  end
end