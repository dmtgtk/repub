module Repub
  class App
    module Logger

      def log
        if @log.nil?
          @log = Helper.new(options[:verbosity])
        end
        @log  
      end
      
      class Helper
        
        LEVEL_QUIET = -1
        LEVEL_NORMAL = 0
        LEVEL_VERBOSE = 1
        
        # Create a new log instance
        # Level sets verbosity level:
        #   -1 : quiet (nothing except errors)
        #    0 : normal
        #    1 : verbose
        def initialize(level = LEVEL_NORMAL)
          @level = level
        end
        
        def debug(msg)
          if @level < LEVEL_NORMAL
            puts msg
          end
        end
        alias_method :info, :debug
        
        def error
          if @level > LEVEL_NORMAL
            STDERR.puts msg
          end
        end
        alias_method :warn, :error
        
        def fatal(msg)
          error msg
          exit 1
        end
      end

    end
  end
end
