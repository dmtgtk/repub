require 'fileutils'
require 'digest/sha1'
require 'uri'

module Repub
  
  class FetcherException < Exception; end

  #wget -nv -E -H -k -p -nH -nd -R '*.txt' http://www.berzinarchives.com/web/x/prn/p.html_272733222.html

  class Fetcher
    
    WgetHelper = 'wget'
    HttrackHelper = 'httrack'
    
    HelperOptions = {
      WgetHelper => '-nv -E -H -k -p -nH -nd',
      HttrackHelper => '-gB -r2 +*.css +*.jpg -*.xml -*.html'
    }
    
    class Cache
      CACHE_ROOT = File.join(File.expand_path('~'), %w[.repub cache])
      
      def self.root
        return CACHE_ROOT
      end
      
      def self.inventorize
        # TODO 
      end
      
      attr_reader :url
      attr_reader :name
      attr_reader :path
      
      def self.for_url(url, &block)
        self.new(url).for_url(&block)
      end
      
      def for_url(&block)
        unless File.exist?(@path)
          FileUtils.mkdir_p(@path) 
          begin
            FileUtils.chdir(@path) { yield }
          rescue
            FileUtils.rm_r(@path)
            raise
          end
        end
        self
      end
      
      private
      
      def initialize(url)
        @url = url
        @name = Digest::SHA1.hexdigest(@url)
        @path = File.join(CACHE_ROOT, @name)
      end
    end
    
    attr_accessor :helper_path
    attr_accessor :helper_options
    
    def self.get(url, helper = Fetcher::WgetHelper)
      (self.new(url, helper)).get
    end
    
    def get
      cmd = "#{@helper_path} #{@helper_options} #{@url}"
      Cache.for_url(@url) do
        unless system(cmd)
          raise FetcherException, "Fetch failed."
        end
      end
    end
  
    private
    
    def initialize(url, helper = WgetHelper, helper_options = HelperOptions[WgetHelper])
      raise FetcherException, "empty URL" if url.empty?
      begin
        URI.parse(url)
      rescue
        raise FetcherException, "invalid URL: #{url}"
      end
      @url = url
      @helper_path = ENV['REPUB_HELPER']
      @helper_path ||= which_helper(helper)
      @helper_options = ENV['REPUB_HELPER_OPTIONS']
      @helper_options ||= HelperOptions[helper]
    end
    
    def which_helper(helper)
      p helper
      res = `/usr/bin/which #{helper}`.strip
      p res
      if res.empty?
        raise FetcherException, "#{helper}: helper not found."
      end
      res
    end
    
  end

end
