require 'rubygems'
require 'builder'
require 'fileutils'

module Repub

  class WriterException < RuntimeError; end
  
  class Writer
    
    def initialize(parser, cache, output_path = nil)
      @cache = cache
      @parser = parser
      if output_path
        @output_path = File.join(output_path, parser.title)
      else
        @output_path = parser.title
      end
      @content = Epub::Content.new(@parser.uid)
      @toc = Epub::Toc.new(@parser.uid)
    end
    
    def write
      FileUtils.mkdir_p(@output_path)
      FileUtils.chdir(@output_path) do
        write_meta_inf
        write_mime_type
        write_assets
        write_content
        write_toc
        make_epub
      end
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
    
    def write_assets
      @cache.assets[:documents].each do |a|
        FileUtils.cp(File.join(@cache.path, a), '.')
        @content.add_document(a)
      end
      @cache.assets[:stylesheets].each do |a|
        FileUtils.cp(File.join(@cache.path, a), '.')
        @content.add_stylesheet(a)
      end
      @cache.assets[:images].each do |a|
        FileUtils.cp(File.join(@cache.path, a), '.')
        @content.add_image(a)
      end
    end
    
    def write_content
      @content.metadata.title = @parser.title
      @content.metadata.description = @parser.subtitle
      @content.save
    end
    
    def write_toc
      @toc.title = @parser.title
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
      filename = "#{@parser.title}.epub"
      # TODO ==
      system("zip -X9 '#{filename}' mimetype >/dev/null")
      system("zip -Xr9D '#{filename}' * -xi mimetype >/dev/null")
      # ==
      FileUtils.mv(filename, '..')
    end
  end

end
