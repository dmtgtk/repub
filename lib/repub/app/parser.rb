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
      @toc = parse_toc
      #p @toc.count
      #pp @toc
      yield self if block
      self
    end
    
    Selectors = {
      :title        => '//h1',
      :toc          => '//div.toc/ul',
      :toc_item     => '/li',
      :toc_section  => '/ul'
    }
    
    def parse_title
      @document.at(@selectors[:title]).inner_text.gsub(/[\r\n]/, '').gsub(/\s+/, ' ')
    end
    
    def parse_title_html
      @document.at(@selectors[:title]).inner_html.gsub(/[\r\n]/, '')
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
      parse_toc_section(@document.at(@selectors[:toc]))
    end
    
    def parse_toc_section(section)
      toc = []
      section.search(@selectors[:toc_item]).each do |item|
        #puts "=== Item ==="
        href = item.at('a')['href']
        next if href.empty?
        title = item.at('a').inner_text
        subitems = nil
        #p "#{title}"
        item.search(@selectors[:toc_section]).each do |subsection|
          #puts '--- Section >>>'
          subitems = parse_toc_section(subsection)
          #puts '<<<'
        end
        toc << TocItem.new(title, href, subitems, @cache.assets[:documents][0])
      end
      toc
    end
  
  end
end
