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
        include Epub, Logger
        
        attr_reader :output_path
        attr_reader :asset_path
        
        def initialize(options)
          @options = options
        end
        
        def build(parser)
          @parser = parser

          # Initialize content.opf
          @content = Content.new(@parser.uid)
          # Default title is the parsed one
          @content.metadata.title = @parser.title
          # Override metadata values specified in options
          if @options[:metadata]
            @content.metadata.members.each do |m|
              m = m.to_sym
              next if m == :identifier   # do not allow to override uid
              if @options[:metadata][m]
                @content.metadata[m] = @options[:metadata][m]
                log.debug "-- Setting metadata #{m} to \"#{@content.metadata[m]}\""
              end
            end
          end
          
          # Initialize toc.ncx
          @toc = Toc.new(@parser.uid)
          # TOC title is the same as in content.opf
          @toc.title = @content.metadata.title

          # Setup output filename and path
          @output_path = File.expand_path(@options[:output_path].if_blank('.'))
          if File.exist?(@output_path) && File.directory?(@output_path)
            @output_path = File.join(@output_path, @content.metadata.title.gsub(/\s/, '_'))
          end
          @output_path = @output_path +  '.epub'
          log.debug "-- Setting output path to #{@output_path}"
          
          # Build EPUB
          tmpdir = Dir.mktmpdir(App::name)
          begin
            FileUtils.chdir(tmpdir) do
              copy_and_process_assets
              write_meta_inf
              write_mime_type
              write_content
              write_toc
              write_epub
            end
          ensure
            # Keep tmp folder if we're going open processed doc in browser
            FileUtils.remove_entry_secure(tmpdir) unless @options[:browser]
          end
          self
        end
        
        private
        
        MetaInf = 'META-INF'
        
        def postprocess_file(asset)
          source = IO.read(asset)
          # Do rx substitutions
          if @options[:rx] && !@options[:rx].empty?
            @options[:rx].each do |rx|
              rx.strip!
              delimiter = rx[0, 1]
              rx = rx.gsub(/\\#{delimiter}/, "\n")
              ra = rx.split(/#{delimiter}/).reject {|e| e.empty? }.each {|e| e.gsub!(/\n/, "#{delimiter}")}
              raise ParserException, "Invalid regular expression" if ra.empty? || ra[0].nil? || ra.size > 2
              pattern = ra[0]
              replacement = ra[1] || ''
              log.info "Replacing pattern /#{pattern.gsub(/#{delimiter}/, "\\#{delimiter}")}/ with \"#{replacement}\""
              source.gsub!(Regexp.new(pattern), replacement)
            end
          end
          # Add doctype if missing
          if source !~ /\s*<!DOCTYPE/
            log.debug "-- Adding missing doctype"
            source = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n" + source
          end
          # Save processed file
          File.open(asset, 'w') do |f|
            f.write(source)
          end
        end
        
        def postprocess_doc(asset)
          doc = Nokogiri::HTML.parse(open(asset), nil, 'UTF-8')
          # Substitute custom CSS
          if (@options[:css] && !@options[:css].empty?)
            doc.xpath('//link[@rel="stylesheet"]') do |link|
              link[:href] = File.basename(@options[:css])
              log.debug "-- Replacing CSS refs with #{link[:href]}"
            end
          end
          # Remove elements
          if @options[:remove] && !@options[:remove].empty?
            @options[:remove].each do |selector|
              log.info "Removing elements matching selector \"#{selector}\""
              #p doc.search(selector).size
              #p doc.search(selector)
              doc.search(selector).remove
            end
          end
          # Save processed doc
          File.open(asset, 'w') do |f|
            if @options[:fixup]
              # HACK: Nokogiri seems to ignore the fact that xmlns and other attrs aleady present
              # in html node and adds them anyway. Just remove them here to avoid duplicates.
              doc.root.attributes.each {|name, value| doc.root.remove_attribute(name) }
              doc.write_xhtml_to(f, :encoding => 'UTF-8')
            else
              doc.write_html_to(f, :encoding => 'UTF-8')
            end
          end
        end
        
        def copy_and_process_assets
          # Copy html
          @parser.cache.assets[:documents].each do |asset|
            log.debug "-- Processing document #{asset}"
            # Copy asset from cache
            FileUtils.cp(File.join(@parser.cache.path, asset), '.')
            # Do post-processing
            postprocess_file(asset)
            postprocess_doc(asset)
            @content.add_document(asset)
            @asset_path = File.expand_path(asset)
          end
          # Copy css
          if @options[:css].nil? || @options[:css].empty?
            # No custom css, copy one from assets
            @parser.cache.assets[:stylesheets].each do |css|
              log.debug "-- Copying stylesheet #{css}"
              FileUtils.cp(File.join(@parser.cache.path, css), '.')
              @content.add_stylesheet(css)
            end
          else
            # Copy custom css
            log.debug "-- Using custom stylesheet #{@options[:css]}"
            FileUtils.cp(@options[:css], '.')
            @content.add_stylesheet(File.basename(@options[:css]))
          end
          # Copy images
          @parser.cache.assets[:images].each do |image|
            log.debug "-- Copying image #{image}"
            FileUtils.cp(File.join(@parser.cache.path, image), '.')
            @content.add_image(image)
          end
        end
        
        def write_meta_inf
          FileUtils.mkdir_p(MetaInf)
          FileUtils.chdir(MetaInf) do
            Epub::Container.new.save
          end
        end
        
        def write_mime_type
          File.open('mimetype', 'w') do |f|
            f << 'application/epub+zip'
          end
        end
    
        def write_content
          @content.save
        end
        
        def write_toc
          add_nav_points(@toc.nav_map, @parser.toc)
          @toc.save
        end
        
        def add_nav_points(nav_collection, toc)
          toc.each do |t|
            nav_point = nav_collection.add_nav_point(t.title, t.src)
            add_nav_points(nav_point, t.subitems) if t.subitems
          end
        end
        
        def write_epub
          %x(zip -X9 \"#{@output_path}\" mimetype)
          %x(zip -Xr9D \"#{@output_path}\" * -xi mimetype)
        end
      end

    end
  end
end
