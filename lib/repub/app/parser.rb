require 'rubygems'
require 'hpricot'

module Repub
  
  class ParserException < Exception; end
  
  class Parser
    
    attr_accessor :selectors
    
    attr_reader :asset_name
    attr_reader :asset_root
    attr_reader :uid
    attr_reader :title
    attr_reader :title_html
    attr_reader :subtitle
    attr_reader :subtitle_html
    attr_reader :toc
    
    def initialize(asset_name, asset_root)
      @asset_name, @asset_root = asset_name, asset_root
      @selectors = DefaultSelectors
    end
    
    def self.parse(asset_name, asset_root, &block)
      raise ArgumentException, 'block expected' unless block
      parser = new(asset_name, asset_root)
      parser.parse
      yield parser
    end
    
    def parse
      @document = Hpricot(open(File.join(@asset_root, @asset_name)))
      @uid = parse_uid
      @title = parse_title
      @title_html = parse_title_html
      @subtitle = parse_subtitle
      @subtitle_html = parse_subtitle_html
      @toc = parse_toc
    end
    
    DefaultSelectors = {
      :title => '//h1',
      :subtitle => 'p.subtitle1',
      :toc => 'div.toc/div'
    }
    
    def parse_uid
      @asset_name.gsub(/\.html?$/, '.epub')
    end
  
    def parse_title
      @document.search(@selectors[:title]).inner_text.gsub(/[\r\n]/, '').gsub(/\s+/, ' ')
    end
    
    def parse_title_html
      @document.search(@selectors[:title]).inner_html.gsub(/[\r\n]/, '')
    end
    
    def parse_subtitle
      @document.search(@selectors[:subtitle]).inner_text.gsub(/[\r\n]/, '').gsub(/\s+/, ' ')
    end
    
    def parse_subtitle_html
      @document.search(@selectors[:subtitle]).inner_html.gsub(/[\r\n]/, '')
    end
    
    class TocItem < Struct.new(
        :title,
        :uri,
        :fragment_id
      )
      
      def initialize(title, uri_with_fragment_id, asset)
        self.title = title
        self.uri, self.fragment_id = uri_with_fragment_id.split(/#/)
        self.uri = asset if self.uri.empty?
      end
      
      def src
        "#{uri}##{fragment_id}"
      end
    end
    
    def parse_toc(selector = nil)
      toc_selector = selector || @selectors[:toc]
      toc = []
      @document.search(toc_selector).each do |item|
        toc_href = item.at('a')['href']
        next if toc_href.empty?
        toc_title = item.at('a').inner_text
        toc << TocItem.new(toc_title, toc_href, @asset_name)
      end
      toc
    end
  end
end
