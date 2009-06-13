require 'rubygems'
require 'builder'
require 'fileutils'

module Repub

  class WriterException < RuntimeError; end
  
  class Writer
    
    def initialize(parser, cache, options)
      @cache = cache
      @parser = parser
      @options = options
      @content = Epub::Content.new(@parser.uid)
      @toc = Epub::Toc.new(@parser.uid)
      
      @content.metadata.title = @parser.title
      @content.metadata.description = @parser.subtitle
      if @options[:metadata]
        @content.metadata.members.each do |m|
          next if m == 'identifier'   # do not allow to override uid
          @content.metadata[m] = @options[:metadata][m] if @options[:metadata][m]
        end
      end
    end
    
    def write
      output_path = @content.metadata.title
      output_path = File.join(@options[:output_path], output_path) if @options[:output_path]
      FileUtils.mkdir_p(output_path)
      FileUtils.chdir(output_path) do
        write_meta_inf
        write_mime_type
        write_assets
        write_content
        write_toc
        make_epub
      end
      # FileUtils.rm_r(output_path)
      @epub
    end
    
    def self.write(parser, cache, output_path = nil)
      self.new(parser, cache, output_path).write
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
      @cache.assets[:documents].each do |a|
        if @options[:css].empty?
          # copy file verbatim
          FileUtils.cp(File.join(@cache.path, a), '.')
        else
          # custom css - fix css references
          doc = Hpricot(open(File.join(@cache.path, a)))
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
        @cache.assets[:stylesheets].each do |a|
          FileUtils.cp(File.join(@cache.path, a), '.')
          @content.add_stylesheet(a)
        end
      else
        # otherwise copy custom css
        FileUtils.cp(@options[:css], '.')
        @content.add_stylesheet(File.basename(@options[:css]))
      end
      @cache.assets[:images].each do |a|
        FileUtils.cp(File.join(@cache.path, a), '.')
        @content.add_image(a)
      end
    end
    
    def write_content
      @content.save
    end
    
    def write_toc
      @toc.title = @content.metadata.title
      add_nav_points(@toc.nav_map, @parser.toc)
      @toc.save
    end
    
    def add_nav_points(nav_collection, toc)
      toc.each do |t|
        nav_point = nav_collection.add_nav_point(t.title, t.src)
        t.subitems.each do |st|
          add_nav_points(nav_point, st.title, st.src)
        end
      end
    end
    
    def make_epub
      @epub = "#{@content.metadata.title}.epub"
      # TODO ==
      system("zip -X9 '#{@epub}' mimetype >/dev/null")
      system("zip -Xr9D '#{@epub}' * -xi mimetype >/dev/null")
      # ==
      FileUtils.mv(@epub, '..')
    end
  end

end
