require 'repub/app/options'
require 'repub/app/profile'
require 'repub/app/fetcher'
require 'repub/app/parser'
require 'repub/app/writer'
require 'repub/app/utility'

module Repub
  class App
    
    # Mix-in actual functionality
    include Options, Profile, Fetcher, Parser, Writer

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
      #p options
      puts "Source:\t\t#{options[:url]}"
      res = write(parse(fetch))
      puts "Output:\t\t#{res.output_path}"
    rescue RuntimeError => ex
      STDERR.puts "ERROR: #{ex.to_s}"
      exit 1
    end
  
  end
end
