#require 'rubygems'
#require 'builder'
require 'fileutils'
require 'tmpdir'
require 'repub/epub'

module Repub
  class App
    module Writer

      class WriterException < RuntimeError; end
      
      def write(parser)
        Helper.new(options).write(parser)
      end
  
      class Helper
        include Epub
        
        attr_reader :output_path
        
        def initialize(options)
          @options = options
          @css = options[:css]
          @fixup = options[:fixup]
          @remove = options[:remove]
          @rx = options[:rx]
        end
        
        def write(parser)
          @parser = parser

          # Initialize content.opf
          @content = Content.new(@parser.uid)
          # Default title is the parsed one
          @content.metadata.title = @parser.title
          if @options[:metadata]
            # Override metadata values specified in options
            @content.metadata.members.each do |m|
              m = m.to_sym
              next if m == :identifier   # do not allow to override uid
              @content.metadata[m] = @options[:metadata][m] if @options[:metadata][m]
            end
          end
          
          # Initialize toc.ncx
          @toc = Toc.new(@parser.uid)
          # TOC title is the same as in content
          @toc.title = @content.metadata.title

          # Setup output filename and path
          @output_path = File.expand_path(@options[:output_path].if_blank('.'))
          if File.exist?(@output_path) && File.directory?(@output_path)
            @output_path = File.join(@output_path, @content.metadata.title.gsub(/\s/, '_'))
          end
          @output_path = @output_path +  '.epub'
          
          # Write EPUB
          Dir.mktmpdir(App::name) do |tmp|
            FileUtils.chdir(tmp) do
              copy_and_process_assets
              write_meta_inf
              write_mime_type
              write_content
              write_toc
              make_epub
            end
          end
          self
        end
        
        private
        
        MetaInf = 'META-INF'
        
        def postprocess_file(asset)
          source = IO.read(asset)
          # Do rx substitutions
          if @rx && !@rx.empty?
            @rx.each do |rx|
              rx.strip!
              delimiter = rx[0, 1]
              rx = rx.gsub(/\\#{delimiter}/, "\n")
              ra = rx.split(/#{delimiter}/).reject {|e| e.empty? }.each {|e| e.gsub!(/\n/, "#{delimiter}")}
              p ra
              raise ParserException, "Invalid regular expression" if ra.empty? || ra[0].nil?
              pattern = ra[0]
              replacement = ra[1] || ''
              puts "Replacing:\t/#{pattern}/ => \"#{replacement}\""
              source.gsub!(Regexp.new(pattern), replacement)
              exit
            end
          end
          # Add doctype if missing
          if source !~ /\s*<!DOCTYPE/
            source = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n" + source
          end
          # Overwrite asset with fixed version
          File.open(asset, 'w') do |f|
            f.write(source)
          end
        end
        
        def postprocess_doc(asset)
          # Do Hpricot fixes if fixup is ON
          doc = Hpricot(open(asset), :xhtml_strict => @fixup)
          # Substitute custom stylesheet
          if (@css && !@css.empty?)
            doc.search('//link[@rel="stylesheet"]') do |link|
              link[:href] = File.basename(@css)
            end
          end
          # Remove elements
          if @remove && !@remove.empty?
            @remove.each do |selector|
              puts "Removing:\t#{selector}"
              doc.search(selector).remove
            end
          end
          # Overwrite asset with fixed version
          File.open(asset, 'w') do |f|
            f << doc.to_html
          end
        end
        
        def copy_and_process_assets
          # Copy html
          @parser.cache.assets[:documents].each do |asset|
            # Copy asset from cache
            FileUtils.cp(File.join(@parser.cache.path, asset), '.')
            # Do post-processing
            postprocess_file(asset)
            postprocess_doc(asset)
            @content.add_document(asset)
          end
          # Copy css
          if @css.nil? || @css.empty?
            # No custom css, copy one from assets
            @parser.cache.assets[:stylesheets].each do |css|
              FileUtils.cp(File.join(@parser.cache.path, css), '.')
              @content.add_stylesheet(css)
            end
          else
            # Copy custom css
            FileUtils.cp(@css, '.')
            @content.add_stylesheet(File.basename(@css))
          end
          # Copy images
          @parser.cache.assets[:images].each do |image|
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
        
        def make_epub
          %x(zip -X9 \"#{@output_path}\" mimetype)
          %x(zip -Xr9D \"#{@output_path}\" * -xi mimetype)
        end
      end

    end
  end
end
