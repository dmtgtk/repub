require 'rubygems'
require 'builder'
require 'fileutils'

module Repub

  class WriterException < RuntimeError; end
  
  class Writer
    
    def initialize(parser, output_path = nil)
      @parser = parser
      if output_path
        @output_path = File.join(output_path, parser.title)
      else
        @output_path = parser.title
      end
      @content = Content.new(@parser.uid)
      @toc = Toc.new(@parser.uid)
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
    
    def self.write(parser, output_path = nil)
      new(parser, output_path).write
    end
    
    private
    
    MetaInf = 'META-INF'
    
    def write_meta_inf
      FileUtils.mkdir_p(MetaInf)
      FileUtils.chdir(MetaInf) do
        Container.new.save
      end
    end
    
    def write_mime_type
      File.open('mimetype', 'w') do |f|
        f << 'application/epub+zip'
      end
    end
    
    def write_assets
      Dir.glob(File.join(@parser.asset_root, '*.html')).each do |a|
        FileUtils.cp(a, '.')
        @content.add_html(File.basename(a))
      end
      Dir.glob(File.join(@parser.asset_root, '*.css')).each do |a|
        FileUtils.cp(a, '.')
        @content.add_css(File.basename(a))
      end
      Dir.glob(File.join(@parser.asset_root, '*.{jpeg,jpg,gif,png,svg}')).each do |a|
        FileUtils.cp(a, '.')
        @content.add_img(File.basename(a))
      end
      Dir.glob(File.join(@parser.asset_root, '*.xpgt')).each do |a|
        FileUtils.cp(a, '.')
        @content.add_page_template(File.basename(a))
      end
    end
    
    def write_content
      @content.metadata.title = @parser.title
      @content.metadata.description = @parser.subtitle
      @content.save
    end
    
    def write_toc
      @toc.title = @parser.title
      @parser.toc.each do |t|
        @toc.nav_map.add_nav_point(t.title, t.src)
      end
      @toc.save
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
