require 'fileutils'
require 'tmpdir'
require 'repub/epub'

module Repub
  class App
    module Builder

      class BuilderException < RuntimeError; end
      
      def build(parser)
        Builder.new(options).build(parser)
      end
  
      class Builder
        include Logger
        
        attr_reader :output_path
        attr_reader :document_path
        
        def initialize(options)
          @options = options
        end
        
        def build(parser)
          @parser = parser

          # Initialize Container
          @ocf = Epub::OCF.new
          
          # Initialize Package
          @opf = Epub::OPF.new(@parser.uid)
          @ocf << @opf
          # Default title is the parsed one
          @opf.metadata.title = @parser.title
          # Override metadata values specified in options
          if @options[:metadata]
            @opf.metadata.members.each do |m|
              m = m.to_sym
              # Do not allow to override uid
              next if m == :identifier
              if @options[:metadata][m]
                @opf.metadata[m] = @options[:metadata][m]
                log.debug "-- Setting metadata #{m} to \"#{@opf.metadata[m]}\""
              end
            end
          end
          
          # Initialize TOC
          @ncx = Epub::NCX.new(@parser.uid)
          @opf << @ncx
          @ncx.title = @opf.metadata.title
          @ncx.nav_map.points = @parser.toc

          # Setup output filename and path
          @output_path = File.expand_path(@options[:output_path].if_blank('.'))
          if File.exist?(@output_path) && File.directory?(@output_path)
            @output_path = File.join(@output_path, @opf.metadata.title.gsub(/\s/, '_'))
          end
          @output_path = @output_path +  '.epub'
          log.debug "-- Output path is #{@output_path}"
          
          # Build EPUB
          tmpdir = Dir.mktmpdir(App::name)
          begin
            FileUtils.chdir(tmpdir) do
              copy_and_process_assets
              @ncx.save
              @opf.save
              @ocf.save
              @ocf.zip(@output_path)
            end
          ensure
            # Keep tmp folder if we're going open processed doc in browser
            FileUtils.remove_entry_secure(tmpdir) unless @options[:browser]
          end
          self
        end
        
        private
        
        def copy_and_process_assets
          # Copy html
          @parser.cache.assets[:documents].each do |file|
            log.debug "-- Processing document #{file}"
            # Copy asset from cache
            FileUtils.cp(File.join(@parser.cache.path, file), '.')
            # Do post-processing
            apply_file_filters(file)
            apply_document_filters(file)
            @opf << file
            @document_path = File.expand_path(file)
          end

          # Copy css
          if @options[:css].nil? || @options[:css].empty?
            # No custom css, copy one from assets
            @parser.cache.assets[:stylesheets].each do |css|
              log.debug "-- Copying stylesheet #{css}"
              FileUtils.cp(File.join(@parser.cache.path, css), '.')
              @opf << css
            end
          elsif @options[:css] != '-'
            # Copy custom css
            log.debug "-- Using custom stylesheet #{@options[:css]}"
            FileUtils.cp(@options[:css], '.')
            @opf << File.basename(@options[:css])
          end

          # Copy images
          @parser.cache.assets[:images].each do |image|
            log.debug "-- Copying image #{image}"
            FileUtils.cp(File.join(@parser.cache.path, image), '.')
            @opf << image
          end

          # Copy external custom files (-a option)
          @options[:add].each do |file|
            log.debug "-- Copying external file #{file}"
            FileUtils.cp(file, '.')
            @opf << File.basename(file)
          end if @options[:add]
        end

        def apply_file_filters(file)
          s = PostFilters::FileFilters.apply_filters(IO.read(file), @options)
          File.open(file, 'w') { |f| f.write(s) }
        end
        
        def apply_document_filters(file)
          doc = Nokogiri::HTML.parse(IO.read(file), nil, 'UTF-8')
          doc = PostFilters::DocumentFilters.apply_filters(doc, @options)
          File.open(file, 'w') do |f|
            # HACK: Nokogiri seems to ignore the fact that xmlns and other attrs aleady present
            # in html node and adds them anyway. Just remove them here to avoid duplicates.
            doc.root.attributes.each {|name, value| doc.root.remove_attribute(name) }
            doc.write_xhtml_to(f, :encoding => 'UTF-8')
          end
        end
        
        # def postprocess_file(asset)
        #   source = IO.read(asset)
        # 
        #   # Do rx substitutions
        #   @options[:rx].each do |rx|
        #     rx.strip!
        #     delimiter = rx[0, 1]
        #     rx = rx.gsub(/\\#{delimiter}/, "\n")
        #     ra = rx.split(/#{delimiter}/).reject {|e| e.empty? }.each {|e| e.gsub!(/\n/, "#{delimiter}")}
        #     raise ParserException, "Invalid regular expression" if ra.empty? || ra[0].nil? || ra.size > 2
        #     pattern = ra[0]
        #     replacement = ra[1] || ''
        #     log.info "Replacing pattern /#{pattern.gsub(/#{delimiter}/, "\\#{delimiter}")}/ with \"#{replacement}\""
        #     source.gsub!(Regexp.new(pattern), replacement)
        #   end if @options[:rx]
        # 
        #   # Remove xml preamble if any
        #   preamble_rx = /^\s*<\?xml\s+[^>]+>\s*/mi
        #   if source =~ preamble_rx
        #     log.debug "-- Removing xml preamble"
        #     source.sub!(preamble_rx, '')
        #   end
        #   
        #   # Replace doctype
        #   doctype_rx = /^\s*<!DOCTYPE\s+[^>]+>\s*/mi
        #   if source =~ doctype_rx
        #     source.sub!(doctype_rx, '')
        #   end
        #   log.debug "-- Replacing doctype"
        #   source = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n" + source
        #   
        #   # Save processed file
        #   File.open(asset, 'w') do |f|
        #     f.write(source)
        #   end
        # end
        
        # def postprocess_doc(asset)
        #   doc = Nokogiri::HTML.parse(IO.read(asset), nil, 'UTF-8')
        #   
        # # Set Content-Type charset to UTF-8
        # doc.xpath('//head/meta[@http-equiv="Content-Type"]').each do |el|
        #   el['content'] = 'text/html; charset=utf-8'
        # end
        # 
        # # Process styles
        # if @options[:css] && !@options[:css].empty?
        #   # Remove all stylesheet links
        #   doc.xpath('//head/link[@rel="stylesheet"]').remove
        #   if @options[:css] == '-'
        #     # Also remove all inline styles
        #     doc.xpath('//head/style').remove
        #     log.info "Removing all stylesheet links and style elements"
        #   else
        #     # Add custom stylesheet link
        #     link = Nokogiri::XML::Node.new('link', doc)
        #     link['rel'] = 'stylesheet'
        #     link['type'] = 'text/css'
        #     link['href'] = File.basename(@options[:css])
        #     # Add as the last child so it has precedence over (possible) inline styles before
        #     doc.at('//head').add_child(link)
        #     log.info "Replacing CSS refs with \"#{link['href']}\""
        #   end
        # end
        # 
        # # Insert elements after/before selector
        # @options[:after].each do |e|
        #   selector = e.keys.first
        #   fragment = e[selector]
        #   element = doc.xpath(selector).first
        #   if element
        #     log.info "Inserting fragment \"#{fragment.to_html}\" after \"#{selector}\""
        #     fragment.children.to_a.reverse.each {|node| element.add_next_sibling(node) }
        #   end
        # end if @options[:after]
        # @options[:before].each do |e|
        #   selector = e.keys.first
        #   fragment = e[selector]
        #   element = doc.xpath(selector).first
        #   if element
        #     log.info "Inserting fragment \"#{fragment}\" before \"#{selector}\""
        #     fragment.children.to_a.each {|node| element.add_previous_sibling(node) }
        #   end
        # end if @options[:before]
        # 
        # # Remove elements
        # @options[:remove].each do |selector|
        #   log.info "Removing elements \"#{selector}\""
        #   doc.search(selector).remove
        # end if @options[:remove]
        # 
        # # XXX
        # # doc.xpath('//body/a').each do |a|
        # #   wrapper = Nokogiri::XML::Node.new('p', doc)
        # #   a.add_next_sibling(wrapper)
        # #   wrapper << a
        # # end
        # 
        #   # Save processed doc
        #   File.open(asset, 'w') do |f|
        #     # HACK: Nokogiri seems to ignore the fact that xmlns and other attrs aleady present
        #     # in html node and adds them anyway. Just remove them here to avoid duplicates.
        #     doc.root.attributes.each {|name, value| doc.root.remove_attribute(name) }
        #     doc.write_xhtml_to(f, :encoding => 'UTF-8')
        #   end
        # end
      end

    end
  end
end
