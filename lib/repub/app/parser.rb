require 'rubygems'
require 'nokogiri'
require 'repub/epub'

module Repub
  class App
    module Parser
  
      class ParserException < RuntimeError; end
      
      def parse(cache)
        Parser.new(options).parse(cache)
      end
  
      # Default selectors, some reasonable values
      #
      Selectors = {
        :title        => '//h1',
        :toc          => '//ul',
        :toc_item     => './li',
        :toc_section  => './ul'
      }
      
      class Parser
        include Logger
        
        attr_reader :cache
        attr_reader :uid
        attr_reader :title
        attr_reader :toc
        
        def initialize(options)
          @selectors = options[:selectors] || Selectors
          @fixup = options[:fixup]
        end
        
        # Parse downloaded asset cache
        #
        def parse(cache)
          raise ParserException, "No HTML document found" if
            cache.assets[:documents].empty?
          # TODO: limited to a single document only
          raise ParserException, "More than one HTML document found, this is not supported (yet)" if
            cache.assets[:documents].size > 1
          
          @cache = cache
          @document = @cache.assets[:documents][0]
          log.debug "-- Parsing #{@document}"
          @doc = Nokogiri::HTML.parse(IO.read(File.join(@cache.path, @document)), nil, 'UTF-8')
          
          @uid = @cache.name
          parse_title
          parse_toc
          self
        end
        
        private

        # Parse document title
        #
        def parse_title
          log.debug "-- Looking for title with #{@selectors[:title]}"
          el = @doc.at(@selectors[:title])
          if el
            if el.children.empty?
              title_text = el.inner_text
            else
              title_text = el.children.map{|c| c.inner_text }.join(' ')
            end
            @title = title_text.gsub(/[\r\n]/, '').gsub(/\s+/, ' ').strip
            log.info "Found title \"#{@title}\""
          else
            @title = 'Untitled'
            log.warn "** Could not find document title, using '#{@title}'"
          end
        end

        # Parsed TOC item container
        # Inherit from NavPoint to avoid conversions later in Builder
        #
        class TocItem < Repub::Epub::NCX::NavPoint
          
          def initialize(title, uri_with_fragment_id, subitems, document)
            uri, fragment_id = uri_with_fragment_id.split(/#/)
            uri = document if uri.empty?
            super(title, "#{uri}##{fragment_id}", subitems)
          end
        
        end

        # Look for TOC and recursively parse it
        #
        def parse_toc
          @toc = []
          depth = 0
          
          l = lambda do |section|
            toc_items = []
            depth += 1
            section.xpath(@selectors[:toc_item]).each do |item|
              # Get item's anchor and href
              a = item.name == 'a' ? item : item.at('a')
              next if !a
              href = a['href']
              next if !href
              
              # Is this a leaf item or node? Title parsing depends on that.
              subsection = item.xpath(@selectors[:toc_section]).first
              if subsection
                # Item has subsection, use anchor text for title
                title = a.inner_text
              else
                # Leaf item, it is safe to glue inner_text from all children
                title = item.children.map{|c| c.inner_text }.join(' ')
              end
              title = title.gsub(/[\r\n]/, '').gsub(/\s+/, ' ').strip
              log.debug "-- #{"  " * depth}#{title}"
              
              # Parse subsection
              subitems = l.call(subsection) if subsection
              
              toc_items << TocItem.new(title, href, subitems, @document)
            end
            depth -= 1
            toc_items
          end

          log.debug "-- Looking for TOC with #{@selectors[:toc]}"
          toc_element = @doc.xpath(@selectors[:toc]).first
          
          if toc_element
            log.debug "-- Found TOC, parsing items with #{@selectors[:toc_item]} and sections with #{@selectors[:toc_section]}"
            @toc = l.call(toc_element)
            log.info "Found TOC with #{@toc.size} top-level items"
          else
            log.warn "** Could not find document table of contents"
          end
        end
      end

    end
  end    
end
