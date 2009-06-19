require 'rubygems'
require 'hpricot'

module Repub
  class App
    module Parser
  
      class ParserException < RuntimeError; end
      
      def parse(cache)
        Helper.new(options).parse(cache)
      end
  
      # Default hpricot selectors
      #
      Selectors = {
        :title        => '//h1',
        :toc          => '//div.toc/ul',
        :toc_item     => '/li',
        :toc_section  => '/ul'
      }
      
      class Helper
        attr_reader :cache
        attr_reader :uid
        attr_reader :title
        attr_reader :title_html
        attr_reader :toc
        
        def initialize(options)
          @selectors = options[:selectors] || Selectors
        end
        
        def parse(cache)
          raise ParserException, "No HTML document found" if
            cache.assets[:documents].empty?
          raise ParserException, "More than HTML document found, this is not supported (yet)" if
            cache.assets[:documents].size > 1
          
          @cache = cache
          @asset = @cache.assets[:documents][0]
          @doc = Hpricot(open(File.join(@cache.path, @asset)))
          @uid = @cache.name
          @title = parse_title
          @title_html = parse_title_html
          @toc = parse_toc
          #p @toc.count
          #pp @toc
          self
        end
        
        private
        
        def parse_title
          el = @doc.at(@selectors[:title])
          el ? el.inner_text.gsub(/[\r\n]/, '').gsub(/\s+/, ' ') : 'Untitled'
        end
        
        def parse_title_html
          el = @doc.at(@selectors[:title])
          el ? el.inner_html.gsub(/[\r\n]/, '') : 'Untitled'
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
          parse_toc_section(@doc.at(@selectors[:toc]))
        end
        
        def parse_toc_section(section)
          toc = []
          if section
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
              toc << TocItem.new(title, href, subitems, @asset)
            end
          end
          toc
        end
      end

    end
  end    
end
