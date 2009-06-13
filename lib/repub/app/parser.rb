require 'rubygems'
require 'hpricot'

module Repub
  
  class ParserException < RuntimeError; end
  
  class Parser
    
    attr_accessor :selectors
    
    attr_reader :uid
    attr_reader :title
    attr_reader :title_html
    attr_reader :subtitle
    attr_reader :subtitle_html
    attr_reader :toc
    
    def initialize(cache)
      @cache = cache
      raise ParserException, "No HTML document found" if
        @cache.assets[:documents].empty?
      raise ParserException, "More than HTML document found, this is not supported (yet)" if
        @cache.assets[:documents].size > 1
      @selectors = DefaultSelectors
    end
    
    def self.parse(cache, &block)
      self.new(cache).parse(&block)
    end
    
    def parse(&block)
      @document = Hpricot(open(File.join(@cache.path, @cache.assets[:documents][0])))
      @uid = @cache.name
      @title = parse_title
      @title_html = parse_title_html
      @subtitle = parse_subtitle
      @subtitle_html = parse_subtitle_html
      @toc = parse_toc
      yield self if block
    end
    
    DefaultSelectors = {
      :title => '//h1',
      :subtitle => 'p.subtitle1',
      :toc => 'div.toc',
      :toc_item => 'a'
    }
    
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
        @child_items = []
      end
      
      def src
        "#{uri}##{fragment_id}"
      end
      
      def add_child_item()
        
      end
    end
    
    def parse_toc
      toc = []
      toc_element = @document.search(@selectors[:toc])[0]
      p toc_element
      if toc_element
        # toc_href = item.at('a')['href']
        # next if toc_href.empty?
        # toc_title = item.at('a').inner_text
        # toc << TocItem.new(toc_title, toc_href, @asset_name)
      end
      toc
    end
  end
end
