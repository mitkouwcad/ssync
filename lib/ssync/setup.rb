module Ssync
  class Setup
    class << self
      include Helpers

      CANNED_POLICIES = {:p => :private, :r => :public_read, :w => :public_read_write, :a => :authenticated_read}

      def default_config
        @default_config ||= read_default_config
      end

      def default_config=(config)
        @default_config = config
      end

      def config
        @config ||= read_config
      end

      def config=(config)
        @config = config
      end

      def run!
        display "Welcome to Ssync! You will now be asked for a few questions."

        config[:aws_access_key] = ask config[:aws_access_key], "What is the AWS Access Key ID?"
        config[:aws_secret_key] = ask config[:aws_secret_key], "What is the AWS Secret Access Key?"

        display "Please wait while Ssync is connecting to AWS ..."

        if aws_credentials_is_valid?(config)
          display "Successfully connected to AWS."

          default_config[:last_used_bucket] = config[:aws_dest_bucket] = ask(config[:aws_dest_bucket], "Which bucket would you like to put your backups in? Ssync will create the bucket for you if it doesn't exist.")

          if bucket_exists?(config)
            if bucket_empty?(config)
              display "The bucket exists and is empty, great!"
            else
              e! "The bucket exists but is not empty, we cannot sync to a bucket that is not empty!"
            end
          else
            display "The bucket doesn't exist, creating it now ..."
            create_bucket(config)
            display "The bucket has been created."
          end
        else
          e! "Ssync wasn't able to connect to AWS, please check the credentials you supplied are correct."
        end

        require "pathname"
        config[:local_file_path] = ask config[:local_file_path], "What is the path you would like to backup? (i.e. '/var/www')."
        config[:local_file_path] = Pathname.new(config[:local_file_path]).realpath.to_s

        if local_file_path_exists?(config)
          display "The path is set to '#{config[:local_file_path]}'."
        else
          e! "The path you specified does not exist!"
        end

        config[:s3_file_path] = ask config[:s3_file_path], "What is the destination path on S3? (Leave blank if you wish to have a relative path)"

        config[:find_options] = ask config[:find_options], "Do you have any options for 'find'? (e.g. \! -path *.git*)."

        config[:access] = ask config[:access], "What access control policies do you wish to use? (p)rivate [default], public_(r)ead, public_read_(w)rite or (a)uthenticated_read?"
        config[:access] = CANNED_POLICIES.keys.include?(config[:access].to_sym) ? CANNED_POLICIES[ config[:access].to_sym ] : :private 
        display "Saving configuration data ..."
        write_default_config!(default_config)
        write_config!(config)
        display "All done! The configuration file is stored in '#{config_path}'."
        display "You may now use 'ssync sync' to synchronise your files to the S3 bucket."
      end

      def aws_credentials_is_valid?(config = read_config)
        AWS::S3::Base.establish_connection!(:access_key_id => config[:aws_access_key], :secret_access_key => config[:aws_secret_key])
        begin
          # AWS::S3 don't try to connect at all until you ask it for something.
          AWS::S3::Service.buckets
        rescue AWS::S3::InvalidAccessKeyId => e
          false
        else
          true
        end
      end

      def bucket_exists?(config = read_config)
        AWS::S3::Bucket.find(config[:aws_dest_bucket])
      rescue AWS::S3::NoSuchBucket => e
        false
      end

      def bucket_empty?(config = read_config)
        AWS::S3::Bucket.find(config[:aws_dest_bucket]).empty?
      end

      def create_bucket(config = read_config)
        AWS::S3::Bucket.create(config[:aws_dest_bucket])
      end

      def local_file_path_exists?(config = read_config)
        File.exist?(config[:local_file_path])
      end
    end
  end
end
