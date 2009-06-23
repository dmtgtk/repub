module Repub
  class App
    module Logger

      # Logging verbosity:
      #   -1 : quiet (nothing except errors)
      #    0 : normal
      #    1 : verbose (include debug and info)
      LOGGER_QUIET = -1
      LOGGER_NORMAL = 0
      LOGGER_VERBOSE = 1

      def log(stdout = STDOUT, stderr = STDERR)
        if @log.nil?
          @log = Helper.new(options[:verbosity], stdout, stderr)
        end
        @log  
      end
    
      class Helper
        
        # Create a new log instance
        # Level sets verbosity level:
        def initialize(level = LOGGER_NORMAL, stdout = STDOUT, stderr = STDERR)
          @level = level
          @stdout = stdout
          @stderr = stderr
        end
        
        def debug(msg)
          @stdout.puts(msg) if @level < LOGGER_NORMAL
        end
        
        def info(msg)
          @stdout.puts(msg) if @level >= LOGGER_NORMAL
        end
        
        def error(msg)
          @stderr.puts(msg) if @level >= LOGGER_QUIET
        end
        alias_method :warn, :error
        
        def fatal(msg)
          error(msg)
          exit 1
        end
      end

    end
  end
end
