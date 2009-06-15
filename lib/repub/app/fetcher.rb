require 'fileutils'
require 'digest/sha1'
require 'uri'

module Repub
  class App
    module Fetcher
    
      class FetcherException < RuntimeError; end

      def fetch
        FetchHelper.new(options[:helper]).fetch(options[:url])
      end
    
      AssetTypes = {
        :documents => %w[html htm],
        :stylesheets => %w[css],
        :images => %w[jpg jpeg png gif svg]
      }
  
      class Cache
        CACHE_ROOT = File.join(File.expand_path('~'), %w[.repub cache])
      
        def self.root
          return CACHE_ROOT
        end
      
        def self.inventorize
          # TODO 
        end
      
        def self.cleanup
          Dir.chdir(CACHE_ROOT) { FileUtils.rm_r(Dir.glob('*')) }
        rescue
          # ignore exceptions
        end
      
        attr_reader :url
        attr_reader :name
        attr_reader :path
        attr_reader :assets
      
        def self.for_url(url, &block)
          self.new(url).for_url(&block)
        end
      
        def for_url(&block)
          # if not yet cached, download stuff
          unless File.exist?(@path)
            FileUtils.mkdir_p(@path) 
            begin
              Dir.chdir(@path) { yield self }
            rescue
              FileUtils.rm_r(@path)
              raise
            end
          end
          # enumerate assets
          if File.exist?(@path)
            Dir.chdir(@path) do
              @assets = {}
              AssetTypes.each_pair do |asset_type, file_types|
                @assets[asset_type] ||= []
                file_types.each do |file_type|
                  @assets[asset_type] << Dir.glob("*.#{file_type}")
                end
                @assets[asset_type].flatten!
              end
            end
          end
          self
        end
      
        def empty?
          Dir.glob(File.join(@path, '*')).empty?
        end
      
        private
      
        def initialize(url)
          @url = url
          @name = Digest::SHA1.hexdigest(@url)
          @path = File.join(CACHE_ROOT, @name)
        end
      end
      
      class Helper
        HelperCommand = {
          :wget     => { :cmd => 'wget', :options => '-nv -E -H -k -p -nH -nd' },
          :httrack  => { :cmd => 'httrack', :options => '-gB -r2 +*.css +*.jpg -*.xml -*.html' }
        }
        
        def initialize(name)
          @helper_path, @helper_options = ENV['REPUB_HELPER'], ENV['REPUB_HELPER_OPTIONS']
          begin
            helper = HelperCommand[name.to_sym] rescue HelperCommand[:wget]
            @helper_path ||= which(helper[:cmd])
            @helper_options ||= helper[:options]
          rescue
            raise FetcherException, "unknown helper '#{name}'"
          end
        end
        
        def fetch(url)
          raise FetcherException, "empty URL" if url.nil? || url.empty?
          begin
            URI.parse(url)
          rescue
            raise FetcherException, "invalid URL: #{url}"
          end
          cmd = "#{@helper_path} #{@helper_options} #{url}"
          Cache.for_url(url) do |cache|
            unless system(cmd) && !cache.empty?
              raise FetcherException, "Fetch failed."
            end
          end
        end
        
        private
        
        def which
          res = `/usr/bin/which #{helper}`.strip
          raise FetcherException, "#{helper}: helper not found." if res.empty?
          res
        end
      end
      
    end
  end
end
