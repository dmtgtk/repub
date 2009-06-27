require 'test/unit'
require 'rubygems'
require 'nokogiri'
require 'repub/epub'

class TestContainer < Test::Unit::TestCase
  def test_container_create
    c = Repub::Epub::Container.new
    s = c.to_xml
    doc = Nokogiri::HTML(s)
    #puts s
    
    assert_not_nil(doc.search('rootfile'))
  end
end
