require 'singleton'

module Repub
  class App
    module Logger

      # Logging verbosity
      #
      LOGGER_QUIET = 0      # nothing except errors
      LOGGER_NORMAL = 1     # info and above
      LOGGER_VERBOSE = 2    # everything, including debuging noise

      def log
        Logger.instance
      end
      
      class Logger
        include Singleton
        
        attr_accessor :level
        attr_accessor :stdout
        attr_accessor :stderr

        def debug(msg)
          @stdout.puts(msg) if @level >= LOGGER_VERBOSE
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
          exit! 1
        end
        
        private
        def initialize
          @level = LOGGER_NORMAL
          @stdout = STDOUT
          @stderr = STDERR
        end
      end

    end
  end
end
