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
      parse_options(args)
      Repub::Fetcher.get(options[:url]) do |cache|
        Repub::Parser.parse(cache) do |metadata|
          Repub::Writer.write(metadata, cache, options[:output_path])
          puts "#{metadata.title}.epub"
        end
      end
    end
    
    attr_reader :options
    
    def parse_options(args)
      @options = {
        :url            => '',
        :output_path    => '.'
      }

      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          
          RePub is a simple HTML to ePub converter.

          Usage: #{App.name} [options] url

          Options are:
        BANNER
        
        opts.on("-o", "--output=PATH", String,
          "Output path for generated ebooks."
        ) { |value| options[:output_path] = value }
        
        opts.on_tail("--version",
          "Show version."
        ) { puts Repub.version; exit }

        opts.on_tail("-h", "--help",
          "Show this help message."
        ) { puts opts; exit }
        
        if args.empty?
          puts opts
          #warn "Please specify an URL."
          exit
        end
        
        begin
          opts.parse! args
        rescue OptionParser::ParseError => ex
          warn "ERROR: #{ex.to_s}. See '#{App.name} --help'."
          exit
        end
      end
      options[:url] = args[0]
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
