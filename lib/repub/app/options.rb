require 'optparse'

module Repub
  class App
    module Options

      attr_reader :options

      def parse_options(args)
        # Initialize default options
        @options = {
          :url            => nil,
          :css            => nil,
          :output_path    => Dir.getwd,
          :helper         => 'wget',
          :metadata       => {},
          :verbosity      => 0,
          :selectors      => Parser::Selectors
        }

        # Load default profile
        load_profile
        
        p @options

        # Parse command line
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
            p name, value
            p @options[:selectors]
            options[:selectors][name.to_sym] = value
          end

          opts.on("-D", "--downloader NAME ", ['wget', 'httrack'],
              "Which downloader to use to get files (wget or httrack).",
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

          opts.on("-l", "--load-profile NAME", String,
            "Load options from saved profile NAME.",
            "Default profile is always loaded first."
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
        end

        if args.empty?
          help parser
          exit 1
        end
        
        begin
          parser.parse! args
        rescue OptionParser::ParseError => ex
          STDERR.puts "ERROR: #{ex.to_s}. See '#{App.name} --help'."
          exit 1
        end

        options[:url] = args.last
        if options[:url].nil? || options[:url].empty?
          help parser
          STDERR.puts "ERROR: Please specify an URL."
          exit 1
        end
      end

      def help(opts)
        puts opts
        puts
        puts "Current selectors:"
        options[:selectors].keys.map(&:to_s).sort.map do |k|
          printf("    %-33s%s\n", k, options[:selectors][k.to_sym]) 
        end
        puts
      end
    
    end
  end
end