require 'fileutils'
require 'digest/sha1'
require 'uri'
require 'iconv'
require 'rubygems'

old_verbose = $VERBOSE
$VERBOSE = false
require 'UniversalDetector'
$VERBOSE = old_verbose

module Repub
  class App
    module Fetcher
    
      class FetcherException < RuntimeError; end

      def fetch
        Fetcher.new(options).fetch
      end
    
      AssetTypes = {
        :documents => %w[html htm],
        :stylesheets => %w[css],
        :images => %w[jpg jpeg png gif svg]
      }
  
      class Fetcher
        include Logger
        
        Downloaders = {
          :wget     => { :cmd => 'wget', :options => '-nv -E -H -k -p -nH -nd' },
          :httrack  => { :cmd => 'httrack', :options => '-gB -r2 +*.css +*.jpg -*.xml -*.html' }
        }
        
        def initialize(options)
          @options = options
          @downloader_path, @downloader_options = ENV['REPUB_DOWNLOADER'], ENV['REPUB_DOWNLOADER_OPTIONS']
          begin
            downloader = Downloaders[@options[:helper].to_sym] rescue Downloaders[:wget]
            log.debug "-- Using #{downloader[:cmd]} #{downloader[:options]}"
            @downloader_path ||= which(downloader[:cmd])
            @downloader_options ||= downloader[:options]
          rescue RuntimeError
            raise FetcherException, "unknown helper '#{@options[:helper]}'"
          end
        end
        
        def fetch
          url = @options[:url]
          raise FetcherException, "empty URL" if !url || url.empty?
          begin
            URI.parse(url)
          rescue
            raise FetcherException, "invalid URL: #{url}"
          end
          cmd = "#{@downloader_path} #{@downloader_options} #{url}"
          Cache.for_url(url) do |cache|
            log.debug "-- Downloading into #{cache.path}"
            unless system(cmd) && !cache.empty?
              raise FetcherException, "Fetch failed."
            end
          end
        end
        
        private
        
        def which(cmd)
          if !RUBY_PLATFORM.match('mswin')
            cmd = `/usr/bin/which #{cmd}`.strip
            raise FetcherException, "#{cmd}: helper not found." if cmd.empty?
          end
          cmd
        end
      end

      class Cache
        include Logger
        
        def self.root
          return File.join(App.data_path, 'cache')
        end
      
        def self.cleanup
          Dir.chdir(self.root) { FileUtils.rm_r(Dir.glob('*')) }
        rescue
          # ignore exceptions
        end
      
        attr_reader :url
        attr_reader :name
        attr_reader :path
        
        def assets
          inventorize unless @assets
          @assets
        end
      
        def self.for_url(url, &block)
          self.new(url).for_url(&block)
        end
      
        def for_url(&block)
          # Download stuff if not yet cached
          @cached = File.exist?(@path)
          unless @cached
            FileUtils.mkdir_p(@path) 
            begin
              Dir.chdir(@path) { yield self }
            rescue
              FileUtils.rm_r(@path)
              raise
            end
          else
            log.info "Using cached assets"
            log.debug "-- Cache is #{@path}"
          end
          self
        end

        # Do post-download tasks
        #
        def self.inventorize
          Dir.chdir(@path) do
            # Enumerate assets
            @assets = {}
            AssetTypes.each_pair do |asset_type, file_types|
              @assets[asset_type] ||= []
              file_types.each do |file_type|
                @assets[asset_type] << Dir.glob("*.#{file_type}")
              end
              @assets[asset_type].flatten!
            end
            # For freshly downloaded docs, detect encoding and convert to utf-8
            unless cached
              @assets[:documents].each do |doc|
                encoding = @options[:encoding]
                unless encoding
                  log.info "Detecting encoding for #{doc}"
                  s = IO.read(doc)
                  raise FetcherException, "empty document" unless s
                  encoding = UniversalDetector.chardet(s)['encoding']
                end
                if encoding.downcase != 'utf-8'
                  log.info "Source encoding is #{encoding}, converting to UTF-8"
                  s = Iconv.conv('utf-8', encoding, IO.read(doc))
                  File.open(doc, 'w') { |f| f.write(s) }
                else
                  log.info "Looks like UTF-8, no conversion needed"
                end
              end
            end
          end
        end
      
        def empty?
          Dir.glob(File.join(@path, '*')).empty?
        end
      
        private
      
        def initialize(url)
          @url = url
          @name = Digest::SHA1.hexdigest(@url)
          @path = File.join(Cache.root, @name)
        end
      end
      
    end
  end
end
