module Ssync
  module Helpers
    def display_help!
      display("Not implemented yet.")
    end

    def display(message)
      puts("[#{Time.now}] #{message}")
    end

    def display_error(message)
      display("Error! " + message)
    end

    def exit_with_error!(message)
      display_error(message)
      exit
    end

    alias :e :display_error
    alias :e! :exit_with_error!

    def ask(config_item, question)
      print(question + " [#{config_item}]: ")
      a = $stdin.readline.chomp
      a.empty? ? config_item : a
    end

    def action_eq?(action)
      Ssync::Command.action == action.to_sym
    end

    def config_exists?(path = config_path)
      File.exist?(path)
    end

    def ssync_homedir
      "#{ENV['HOME']}/.ssync"
    end

    def ssync_filename
      "#{read_default_config[:last_used_bucket]}"
    end

    def default_config_path
      "#{ssync_homedir}/defaults.yml"
    end

    def config_path
      "#{ssync_homedir}/#{ssync_filename}.yml"
    end

    def lock_path
      "#{ssync_homedir}/#{ssync_filename}.lock"
    end

    def aquire_lock!
      # better way is to write out the pid ($$) and read it back in, to make sure it's the same
      e! "Found a lock at #{lock_path}, is another instance of Ssync running?" if File.exist?(lock_path)

      begin
        system "touch #{lock_path}"
        yield
      ensure
        system "rm #{lock_path}"
      end
    end

    def read_config
      begin
        open(config_path, "r") { |f| YAML::load(f) }
      rescue
        {}
      end
    end

    def read_default_config
      begin
        open(default_config_path, "r") { |f| YAML::load(f) }
      rescue
        {}
      end
    end

    def write_config!(config)
      open(config_path, "w") { |f| YAML::dump(config, f) }
    end

    def write_default_config!(config)
      create_homedir!
      open(default_config_path, "w") { |f| YAML::dump(config, f) }
    end

    def create_homedir!
      `mkdir #{ssync_homedir}` unless File.exists?(ssync_homedir)
    end

    def options_set?(*options)
      false
      [options].flatten.each do |option|
        return true if Command.args.include?("#{option.to_s}")
      end
    end
  end
end