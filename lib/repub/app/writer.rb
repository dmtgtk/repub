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
            @output_path = File.join(@output_path, @content.metadata.title)
          end
          @output_path = @output_path +  '.epub'
          
          # Write EPUB
          # NOTE: Dir::mktmpdir is in >=1.8.7
          Dir.mktmpdir(App::name) do |tmp|
            FileUtils.chdir(tmp) do
              write_meta_inf
              write_mime_type
              write_assets
              write_content
              write_toc
              make_epub
            end
          end
          self
        end
        
        private
        
        MetaInf = 'META-INF'
        
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
    
        # TODO : refactor this mess
        def write_assets
          # copy html
          @parser.cache.assets[:documents].each do |a|
            if @options[:css].empty?
              # copy file verbatim
              FileUtils.cp(File.join(@parser.cache.path, a), '.')
            else
              # custom css - fix css references
              doc = Hpricot(open(File.join(@parser.cache.path, a)))
              doc.search('//link[@rel="stylesheet"]') do |link|
                link[:href] = File.basename(@options[:css])
              end
              File.open(a, 'w') do |f|
                f << doc.to_html
              end
            end
            @content.add_document(a)
          end
          # copy css
          if @options[:css].empty?
            # if no custom css, copy from assets
            @parser.cache.assets[:stylesheets].each do |a|
              FileUtils.cp(File.join(@parser.cache.path, a), '.')
              @content.add_stylesheet(a)
            end
          else
            # otherwise copy custom css instead
            FileUtils.cp(@options[:css], '.')
            @content.add_stylesheet(File.basename(@options[:css]))
          end
          # copy images
          @parser.cache.assets[:images].each do |a|
            FileUtils.cp(File.join(@parser.cache.path, a), '.')
            @content.add_image(a)
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
