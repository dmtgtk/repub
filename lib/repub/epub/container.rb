require 'rubygems'
require 'builder'

module Repub
  module Epub
  
  class Container
    def to_xml
      out = ''
      builder = Builder::XmlMarkup.new(:target => out)
      builder.instruct!
      builder.container :xmlns => "urn:oasis:names:tc:opendocument:xmlns:container", :version => "1.0" do
        builder.rootfiles do
          builder.rootfile 'full-path' => "content.opf", 'media-type' => "application/oebps-package+xml"
        end
      end
      out
    end
  
    def save(path = 'container.xml')
      File.open(path, 'w') do |f|
        f << to_xml
      end
    end
  end

  end
end
