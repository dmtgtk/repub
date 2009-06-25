require 'singleton'
require 'rubygems'
require 'launchy'
require 'repub/app/options'
require 'repub/app/profile'
require 'repub/app/logger'
require 'repub/app/fetcher'
require 'repub/app/parser'
require 'repub/app/writer'
require 'repub/app/utility'

module Repub
  class App
    include Singleton
    
    # Mix-in actual functionality
    include Options, Profile, Fetcher, Parser, Writer, Logger

    def self.name
      File.basename($0)
    end
    
    def self.data_path
      File.join(File.expand_path('~'), '.repub')
    end
    
    def run(args)
      parse_options(args)
      
      log.info "Source:\t\t#{options[:url]}"
      res = write(parse(fetch))
      log.info "Output:\t\t#{res.output_path}"
      
      Launchy::Browser.run(res.asset_path) if options[:browse]
    
    rescue RuntimeError => ex
      log.fatal "** ERROR: #{ex.to_s}"
    end
  
  end
end
