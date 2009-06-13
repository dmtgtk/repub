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
      
      #p options
      puts "Source:\t\t#{options[:url]}"
      puts "Output path:\t#{options[:output_path]}"
      
      Repub::Fetcher.get(options) do |cache|
        Repub::Parser.parse(cache, options) do |parser|
          res = Repub::Writer.write(parser, cache, options)
          puts "EPUB:\t\t#{res}"
        end
      end
    end
    
    attr_reader :options
    
    def parse_options(args)
      @options = {
        :url            => '',
        :css            => '',
        :output_path    => Dir.getwd,
        :helper         => 'wget',
        :metadata       => {}
      }

      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          
          Repub is a simple HTML to ePub converter.

          Usage: #{App.name} [options] url

          Options are:
        BANNER
        
        opts.on("-m", "--meta=NAME:VALUE", String,
          "Set publication information metadata NAME to VALUE.",
          "Names are: title language subject description relation",
          "           creator publisher date rights"
        ) do |value|
          name, value = value.split(/:/)
          options[:metadata][name] = value
        end
        
        opts.on("-d", "--download-helper=NAME", String,
          "Which downloader to use to get files (\"wget\" and \"httrack\" are supported).",
          "Default is #{options[:helper]}."
        ) { |value| options[:helper] = value }
        
        opts.on("-s", "--stylesheet=PATH", String,
          "Use predefined stylesheet to override existing CSS references in the source file."
        ) { |value| options[:css] = File.expand_path(value) }
        
        opts.on("-o", "--output=PATH", String,
          "Output path for generated ePub file.",
          "Default is current directory (#{options[:output_path]})."
        ) { |value| options[:output_path] = File.expand_path(value) }
        
        opts.on_tail("--version",
          "Show version."
        ) { puts Repub.version; exit }

        opts.on_tail("-h", "--help",
          "Show this help message."
        ) { puts opts; exit }
        
        if args.empty?
          puts opts
          exit
        end
        
        begin
          opts.parse! args
        rescue OptionParser::ParseError => ex
          warn "ERROR: #{ex.to_s}. See '#{App.name} --help'."
          exit
        end
        
        options[:url] = args.last
        if options[:url].nil? || options[:url].empty?
          warn "ERROR: Please specify an URL. See '#{App.name} --help'."
          exit
        end
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
