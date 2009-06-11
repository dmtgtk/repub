require 'optparse'

module Repub
  class App

    def self.run(args)
      self.new.run args
    end
    
    def self.name
      File.basename($0)
    end
    
    def run(args)
      parse(args)
    end
    
    attr_reader :options
    
    def parse(args)
      @options = {
        :url      => '',
        :path     => '~'
      }

      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          RePub is a simple HTML to ePub converter.

          Usage: #{App.name} [options] url

          Options are:
        BANNER
        
        opts.separator ""
        
        opts.on("-p", "--path=PATH", String,
          "This is a sample message.",
          "For multiple lines, add more strings.",
          "Default: ~"
        ) { |value| options[:path] = value }
        
        opts.on_tail("--version",
          "Show version."
        ) { puts Repub.version; exit }

        opts.on_tail("-h", "--help",
          "Show this help message."
        ) { puts opts; exit }
        
        if args.empty?
          warn "Please specify an URL."
          exit
        end
        
        begin
          opts.parse! args
        rescue OptionParser::ParseError => ex
          warn "ERROR: #{ex.to_s}. See '#{App.name} --help'."
          exit
        end
        
        p args
        p opts
      end
    end
  end
end


# if ARGV.size == 0
#   puts <<-END
#     usage:
#       #{File.basename(__FILE__)} url [temp]
#   END
#   exit 1
# end
# 
# # begin
#   Repub::Fetcher.fetch(ARGV[0], ARGV[1], true) do |f|
#     Repub::Parser.parse(f.asset_name, f.asset_root) do |p|
#       puts "* Processing:\t#{p.title}"
#       Repub::Writer.write(p)
#       puts "* Done."
#     end
#   end
# # rescue Exception => ex
# #   puts "* Conversion failed: #{ex.message}"
# #   exit 1
# # end
