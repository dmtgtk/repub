require 'rubygems'
require 'hpricot'

module Repub
  
  class ParserException < RuntimeError; end
  
  class Parser
    
    attr_accessor :selectors
    
    attr_reader :document
    attr_reader :uid
    attr_reader :title
    attr_reader :title_html
    attr_reader :subtitle
    attr_reader :subtitle_html
    attr_reader :toc
    
    def initialize(cache, options)
      @cache = cache
      raise ParserException, "No HTML document found" if
        @cache.assets[:documents].empty?
      raise ParserException, "More than HTML document found, this is not supported (yet)" if
        @cache.assets[:documents].size > 1
      @selectors = Selectors
    end
    
    def self.parse(cache, options, &block)
      self.new(cache, options).parse(&block)
    end
    
    def parse(&block)
      @document = Hpricot(open(File.join(@cache.path, @cache.assets[:documents][0])))
      @uid = @cache.name
      @title = parse_title
      @title_html = parse_title_html
      @subtitle = parse_subtitle
      @subtitle_html = parse_subtitle_html
      @toc = parse_toc
      #p @toc.count
      #pp @toc
      yield self if block
      self
    end
    
    Selectors = {
      :title        => '//h1',
      :subtitle     => 'p.subtitle1',
      :toc_root     => '//div.toc',
      :toc_item     => '/div//a',
      :toc_section  => '/div/div//a'
    }
    
    def parse_title
      @document.at(@selectors[:title]).inner_text.gsub(/[\r\n]/, '').gsub(/\s+/, ' ')
    end
    
    def parse_title_html
      @document.at(@selectors[:title]).inner_html.gsub(/[\r\n]/, '')
    end
    
    def parse_subtitle
      @document.at(@selectors[:subtitle]).inner_text.gsub(/[\r\n]/, '').gsub(/\s+/, ' ')
    end
    
    def parse_subtitle_html
      @document.at(@selectors[:subtitle]).inner_html.gsub(/[\r\n]/, '')
    end
    
    class TocItem < Struct.new(
        :title,
        :uri,
        :fragment_id
      )
      
      def initialize(title, uri_with_fragment_id, subitems, asset)
        self.title = title
        self.uri, self.fragment_id = uri_with_fragment_id.split(/#/)
        self.uri = asset if self.uri.empty?
        @subitems = subitems || []
      end

      attr_reader :subitems
      
      def src
        "#{uri}##{fragment_id}"
      end
    end
    
    def parse_toc
      parse_toc_section(@document.at(@selectors[:toc_root]))
    end
    
    def parse_toc_section(section)
      toc = []
      section.search(@selectors[:toc_item]).each do |item|
        href = item['href']
        next if href.empty?
        title = item.inner_text
        subitems = nil
        item.search(@selectors[:toc_section]).each do |subsection|
          puts '=== Got subsection ==='
          subitems = parse_toc_section(subsection)
        end
        toc << TocItem.new(title, href, subitems, @cache.assets[:documents][0])
      end
      toc
    end
  
  end
end
