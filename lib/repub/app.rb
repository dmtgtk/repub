require 'optparse'
require 'repub/app/fetcher'
require 'repub/app/parser'
require 'repub/app/writer'

module Repub
  class App
    
    # Mix-in actual functionality
    include Fetcher, Parser, Writer

    def self.name
      File.basename($0)
    end
    
    def self.run(args)
      self.new(args).run
    end
    
    def initialize(args)
      parse_options(args)
    end

    def run
      #p options
      puts "Source:\t\t#{options[:url]}"
      
      res = write(parse(fetch))
      
      puts "Output path:\t#{res.output_path}"
      puts "Output file:\t#{res.output_file}"

    rescue RuntimeError => ex
      STDERR.puts "ERROR: #{ex.to_s}"
      exit 1
    end
    
    attr_reader :options

    private
    
    def parse_options(args)
      @options = {
        :url            => '',
        :css            => '',
        :output_path    => Dir.getwd,
        :output_file    => '',
        :helper         => 'wget',
        :metadata       => {},
        :verbosity      => 0,
        :selectors      => Parser::Selectors
      }
      
      get_selector_values = lambda do
        options[:selector].keys.map(&:to_s).sort.map {|k| "  #{k}: #{Parser::Selectors[k.to_sym]}"}
      end
      
      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          
          Repub is a simple HTML to ePub converter.

          Usage: #{App.name} [options] url

          Options are:
        BANNER
        
        opts.on("-s", "--stylesheet=PATH", String,
          "Use custom stylesheet at PATH to override existing",
          "CSS references in the source file(s)."
        ) { |value| options[:css] = File.expand_path(value) }
        
        opts.on("-m", "--meta=NAME:VALUE", String,
          "Set publication information metadata NAME to VALUE.",
          "Valid metadata names are: creator date description",
          "language publisher relation rights subject title"
        ) do |value|
          name, value = value.split(/:/)
          options[:metadata][name.to_sym] = value
        end
        
        opts.on("-x", "--selector=NAME:VALUE", String,
          "Set parser selector NAME to VALUE."
        ) do |value|
          name, value = value.split(/:/)
          options[:selector][name.to_sym] = value
        end
        
        opts.on("-D", "--downloader=NAME", String,
          "Which downloader to use to get files (\"wget\" or \"httrack\").",
          "Default is #{options[:helper]}."
        ) { |value| options[:helper] = value }
        
        opts.on("-o", "--output=PATH", String,
          "Output path for generated ePub file.",
          "Default is current directory (#{options[:output_path]})."
        ) { |value| options[:output_path] = File.expand_path(value) }
        
        opts.on("-C", "--cleanup",
          "Clean up download cache."
        ) { Fetcher::Cache.cleanup; exit 1 }

        opts.on("-v", "--verbose",
          "Turn on verbose output."
        ) { options[:verbosity] = 1 }

        opts.on("-q", "--quiet",
          "Turn off any output except errors."
        ) { options[:verbosity] = -1 }
        
        opts.on_tail("-V", "--version",
          "Show version."
        ) { puts Repub.version; exit 1 }

        opts.on_tail("-h", "--help",
          "Show this help message."
        ) { puts opts; exit 1 }
        
        if args.empty?
          puts opts
          exit 1
        end
        
        begin
          opts.parse! args
        rescue OptionParser::ParseError => ex
          STDERR.puts "ERROR: #{ex.to_s}. See '#{App.name} --help'."
          exit 1
        end
        
        options[:url] = args.last
        if options[:url].nil? || options[:url].empty?
          STDERR.puts "ERROR: Please specify an URL. See '#{App.name} --help'."
          exit 1
        end
      end
    end
  
  end
end
