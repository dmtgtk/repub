#!/usr/bin/env ruby

module RePub

  require 'fileutils'
  
  class FetcherException < Exception; end

#wget -nv -E -H -k -p -nH -nd -R '*.txt' http://www.berzinarchives.com/web/x/prn/p.html_272733222.html

  class Fetcher
    
    attr_reader :url
    attr_reader :asset_name
    attr_reader :asset_root

    attr_accessor :httrack_path
    attr_accessor :httrack_options
    
    def initialize(url, fetch_to = nil)
      @url = url
      fetch_to ||= ENV['TEMP'] || ENV['TMP_DIR'] || '/tmp'
      @asset_name = File.basename(@url)
      @asset_root = File.expand_path(File.join(fetch_to, @asset_name.gsub(/\.html?$/, '')))
      @httrack_path = ENV['REPUB_HTTRACK'] || 'httrack'
      @httrack_options = ENV['REPUB_HTTRACK_OPTIONS'] || '-gB -r2 +*.css +*.jpg -*.xml -*.html'
    end
    
    def self.fetch(url, fetch_to = nil, keep_files = false, &block)
      raise ArgumentException, 'block expected' unless block
      fetcher = new(url, fetch_to)
      if File.exist?(fetcher.asset_root)
        puts "* Asset root already exists"
        keep_files = true
      else
        fetcher.fetch
      end
      yield fetcher
    ensure
      FileUtils.rm_r(fetcher.asset_root) unless keep_files
    end
    
    def fetch
      FileUtils.mkdir_p(@asset_root)
      cmd = "#{@httrack_path} #{@url} #{@httrack_options}"
      puts "* Fetching into:\t#{@asset_root}"
      puts "* Fetching using:\t#{cmd}"
      if system("(cd #{@asset_root}; #{cmd}) | grep -i 'error:'")
        puts "* Fetch failed."
        raise FetcherException
      end
    end
  end
end
  
if __FILE__ == $0

  require "test/unit"

  class TestFetcher < Test::Unit::TestCase
    def test_fetcher
      assert_nothing_raised do
        RePub::Fetcher.fetch('http://www.berzinarchives.com/web/x/prn/p.html_272733222.html', 'tmp') do |f|
          assert_equal('http://www.berzinarchives.com/web/x/prn/p.html_272733222.html', f.url)
          assert_equal('p.html_272733222.html', f.asset_name)
          assert_equal('/Users/dg/Projects/repub/tmp/p.html_272733222', f.asset_root)
          assert(File.exist?(File.join(f.asset_root, f.asset_name)), "Fetch failed.")
        end
        #assert(!File.exist?('/Users/dg/Projects/repub/tmp/p.html_272733222'), "Didn't remove asset root.")
      end
      
      f = RePub::Fetcher.new('http://www.berzinarchives.com/web/x/prn/p.html_272733222.html', 'tmp')
      assert_equal('http://www.berzinarchives.com/web/x/prn/p.html_272733222.html', f.url)
      assert_equal('p.html_272733222.html', f.asset_name)
      assert_equal('/Users/dg/Projects/repub/tmp/p.html_272733222', f.asset_root)
      assert_nothing_raised do
        f.fetch
      end
      assert(File.exist?(File.join(f.asset_root, f.asset_name)), "Fetch failed.")
    end
  
    def test_fetcher_fail
      f = RePub::Fetcher.new('http://www.berzinarchives.com/web/x/prn/doesnt-exist.html', 'tmp')
      assert_raise(RePub::FetcherException) do
        f.fetch
      end
    end
  end

end
