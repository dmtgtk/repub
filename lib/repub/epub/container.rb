module RePub
  
  require 'rubygems'
  require 'builder'
  
  class Container
    def to_xml
      out = ''
      builder = Builder::XmlMarkup.new(:target => out, :indent => 4)
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
    
if __FILE__ == $0

  require "test/unit"
  require 'hpricot'

  class TestContainer < Test::Unit::TestCase
    def test_container_create
      c = RePub::Container.new
      s = c.to_xml
      doc = Hpricot(s)
      puts s
      assert_not_nil(doc.search('rootfile'))
    end
  end
  
end