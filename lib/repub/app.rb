require 'repub/app/options'
require 'repub/app/profile'
require 'repub/app/logger'
require 'repub/app/fetcher'
require 'repub/app/parser'
require 'repub/app/writer'
require 'repub/app/utility'
require 'launchy'

module Repub
  class App
    
    # Mix-in actual functionality
    include Options, Profile, Fetcher, Parser, Writer, Logger

    def self.name
      File.basename($0)
    end
    
    def self.data_path
      File.join(File.expand_path('~'), '.repub')
    end
    
    def self.run(args)
      self.new.run(args)
    end
    
    def run(args)
      parse_options(args)
      Logger(options[:verbosity])
      
      logger.info "Source:\t\t#{options[:url]}"
      res = write(parse(fetch))
      logger.info "Output:\t\t#{res.output_path}"
      
      Launchy::Browser.run(res.asset_path) if options[:browse]
    
    rescue RuntimeError => ex
      STDERR.puts "ERROR: #{ex.to_s}"
      exit 1
    end
  
  end
end
