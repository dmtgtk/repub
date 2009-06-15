require 'fileutils'
require 'digest/sha1'
require 'uri'

module Repub
  class App
    module Fetcher
    
      def fetch
        FetchHelper.new(options).fetch
      end
    
      class FetcherException < RuntimeError; end

      class FetchHelper
        WgetHelper = 'wget'
        HttrackHelper = 'httrack'
    
        HelperOptions = {
          WgetHelper => '-nv -E -H -k -p -nH -nd',
          HttrackHelper => '-gB -r2 +*.css +*.jpg -*.xml -*.html'
        }
    
        AssetTypes = {
          :documents => %w[html htm],
          :stylesheets => %w[css],
          :images => %w[jpg jpeg png gif svg]
        }
    
        def initialize(options)
          @url = options[:url]
          raise FetcherException, "empty URL" if @url.nil? || @url.empty?
          begin
            URI.parse(@url)
          rescue
            raise FetcherException, "invalid URL: #{url}"
          end
          @helper_path = ENV['REPUB_HELPER']
          @helper_path ||= which_helper(options[:helper])
          @helper_options = ENV['REPUB_HELPER_OPTIONS']
          @helper_options ||= HelperOptions[options[:helper]]
        end
        
        def fetch
          cmd = "#{@helper_path} #{@helper_options} #{@url}"
          cache = Cache.for_url(@url) do |cache|
            unless system(cmd) && !cache.empty?
              raise FetcherException, "Fetch failed."
            end
          end
          yield cache if block
          cache
        end
        
        private
    
        def which_helper(helper)
          res = `/usr/bin/which #{helper}`.strip
          raise FetcherException, "#{helper}: helper not found." if res.empty?
          res
        end
      end
      
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
    
    end
  end
end
