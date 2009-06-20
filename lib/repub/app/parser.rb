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
          @fixup = options[:fixup]
          @remove = options[:remove]
          @rx = options[:rx]
        end
        
        def parse(cache)
          raise ParserException, "No HTML document found" if
            cache.assets[:documents].empty?
          raise ParserException, "More than one HTML document found, this is not supported (yet)" if
            cache.assets[:documents].size > 1
          
          @cache = cache
          @asset = @cache.assets[:documents][0]

          do_fixups if @fixup
          @doc = Hpricot(open(File.join(@cache.path, @asset)))
          
          @uid = @cache.name
          parse_title
          parse_title_html
          parse_toc
          
          do_rxes if @rx
          do_xpath_removes if @remove
          
          self
        end
        
        private
        
        def do_rxes
          if !@rx.empty?
            s = IO.read(File.join(@cache.path, @asset))
            @rx.each do |rx|
              ra = rx.split(/(^|[^\\])\//).reject(&:empty?)
              raise ParserException, "Invalid regular expression" if ra.empty?
              pattern = ra[0,2].join.gsub(/\\/, '')
              replacement = ra[2,2].join.gsub(/\\/, '')
              puts "Replacing:\t\"#{pattern}\" => \"#{replacement}\""
              s.gsub!(Regexp.new(pattern), replacement)
            end
            # Save fixed document
            File.open(File.join(@cache.path, @asset), 'w') do |f|
              f.write(s)
            end
          end
        end

        def do_xpath_removes
          if !@remove.empty?
            doc = Hpricot(open(File.join(@cache.path, @asset)), :xhtml_strict => true)
            @remove.each do |selector|
              puts "Removing:\t#{selector}"
              doc.search(selector).remove
            end
            # Save fixed document
            File.open(File.join(@cache.path, @asset), 'w') do |f|
              f << doc.to_html
            end
          end
        end
        
        def do_fixups
          if @fixup
            # Open and attempt to fix to be more XHTML-ish
            doc = Hpricot(open(File.join(@cache.path, @asset)), :xhtml_strict => true)
            doctype_missing = IO.read(File.join(@cache.path, @asset)) !~ /\s*<!DOCTYPE/i
            File.open(File.join(@cache.path, @asset), 'w') do |f|
              # Add doctype if missing
              if doctype_missing
                f.puts '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
              end
              # Save fixed document
              f << doc.to_html
            end
          end
        end
        
        UNTITLED = 'Untitled'
        
        def parse_title
          el = @doc.at(@selectors[:title])
          if el
            if el.children.empty?
              title_text = el.inner_text
            else
              title_text =  el.children.map(&:inner_text).join(' ')
            end
            @title = title_text.gsub(/[\r\n]/, '').gsub(/\s+/, ' ')
            puts "Title:\t\t\"#{@title}\""
          else
            @title = UNTITLED
            STDERR.puts "** Could not parse document title, using '#{@title}'"
          end
        end
        
        def parse_title_html
          el = @doc.at(@selectors[:title])
          @title_html = el ? el.inner_html.gsub(/[\r\n]/, '') : UNTITLED
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
          el = @doc.at(@selectors[:toc])
          if el
            @toc = parse_toc_section(el)
            puts "TOC:\t\t#{@toc.size} top-level items "
          else
            @toc = []
            STDERR.puts "** Could not parse document table of contents"
          end
        end
        
        def parse_toc_section(section)
          toc = []
          section.search(@selectors[:toc_item]).each do |item|
            #puts "=== Item ==="
            a = item.at('a')
            next if a.nil?
            href = a['href']
            next if href.nil?
            title = a.inner_text
            subitems = nil
            #p "#{title}"
            item.search(@selectors[:toc_section]).each do |subsection|
              #puts '--- Section >>>'
              subitems = parse_toc_section(subsection)
              #puts '<<<'
            end
            toc << TocItem.new(title, href, subitems, @asset)
          end
          toc
        end
      end

    end
  end    
end
