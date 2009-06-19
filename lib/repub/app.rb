require 'optparse'
require 'repub/app/fetcher'
require 'repub/app/parser'
require 'repub/app/writer'

module Repub
  class App
    
    REPUB_ROOT = File.join(File.expand_path('~'), '.repub')
    
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
      
      puts "Output:\t\t#{res.output_path}"

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
        :helper         => 'wget',
        :metadata       => {},
        :verbosity      => 0,
        :selectors      => Parser::Selectors
      }
      
      @profiles = {}
      
      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          
          Repub is a simple HTML to ePub converter.

          Usage: #{App.name} [options] url

          Options are:
        BANNER
        
        opts.on("-s", "--stylesheet PATH", String,
          "Use custom stylesheet at PATH to override existing",
          "CSS references in the source file(s)."
        ) { |value| options[:css] = File.expand_path(value) }
        
        opts.on("-m", "--meta NAME:VALUE", String,
          "Set publication information metadata NAME to VALUE.",
          "Valid metadata names are: creator date description",
          "language publisher relation rights subject title"
        ) do |value|
          name, value = value.split(/:/)
          options[:metadata][name.to_sym] = value
        end
        
        opts.on("-x", "--selector NAME:VALUE", String,
          "Set parser selector NAME to VALUE."
        ) do |value|
          name, value = value.split(/:/)
          options[:selectors][name.to_sym] = value
        end
        
        opts.on("-D", "--downloader NAME", String,
          "Which downloader to use to get files (\"wget\" or \"httrack\").",
          "Default is #{options[:helper]}."
        ) { |value| options[:helper] = value }
        
        opts.on("-o", "--output PATH", String,
          "Output path for generated ePub file.",
          "Default is current directory (#{options[:output_path]})."
        ) { |value| options[:output_path] = File.expand_path(value) }
        
        opts.on("-w", "--write-profile [NAME]", String,
          "Save given options for later reuse as profile NAME.",
          "If name is omitted, save to the default profile."
        ) { |value| write_profile(value) }
        
        opts.on("-l", "--load-profile [NAME]", String,
          "Load options from saved profile NAME.",
          "If name is omitted, load the default profile."
        ) { |value| load_profile(value) }
        
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
        ) { help opts; exit 1 }
        
        if args.empty?
          help opts
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
      
    PROFILE_PATH = File.join(REPUB_ROOT, 'profiles')
    
    def help(opts)
      puts opts
      puts
      puts "Current selectors:"
      options[:selectors].keys.map(&:to_s).sort.map do |k|
        printf("    %11s: %s\n", k, options[:selectors][k.to_sym]) 
      end
    end
    
    def load_profiles
      @profiles = YAML.load_file(PROFILE_PATH)
    end
    
    def save_profiles
      File.open(PROFILE_PATH, 'w') do |f|
        YAML.dump(@profiles, f)
      end
    end
    
    def write_profile(name)
      p name
      @profiles
    end
  
  end
end
