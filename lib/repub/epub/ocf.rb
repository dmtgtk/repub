require 'rubygems'
require 'fileutils'
require 'builder'

module Repub
  module Epub

  # OEBPS Container Format (OCF) 1.0 wrapper
  # (see http://www.idpf.org/ocf/ocf1.0/download/ocf10.htm)
  #
  class OCF
    
    def initialize
      @items = []
    end
    
    attr_reader :items
    
    def <<(item)
      if item.kind_of? ContainerItem
        @items << item
      elsif item.is_a? String
        @items << Item.new(item)
      else
        raise "Unsupported item class: #{item.class}"
      end
    end
    
    def to_xml
      out = ''
      builder = Builder::XmlMarkup.new(:target => out)
      builder.instruct!
      builder.container :xmlns => "urn:oasis:names:tc:opendocument:xmlns:container", :version => "1.0" do
        builder.rootfiles do
          @items.each do |item|
            builder.rootfile 'full-path' => item.file_path, 'media-type' => item.media_type
          end
        end
      end
      out
    end
  
    def save
      meta_inf = 'META-INF'
      FileUtils.mkdir_p(meta_inf)
      File.open(File.join(meta_inf, 'container.xml'), 'w') do |f|
        f << to_xml
      end
    end
    
    def zip(output_path)
      File.open('mimetype', 'w') do |f|
        f << 'application/epub+zip'
      end
      # mimetype has to be first in the archive
      %x(zip -X9 \"#{output_path}\" mimetype)
      %x(zip -Xr9D \"#{output_path}\" * -xi mimetype)
    end
  end

  end
end
