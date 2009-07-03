require 'test/unit'
require 'rubygems'
require 'nokogiri'
require 'repub/epub'

class TestContainer < Test::Unit::TestCase
  def test_container_create
    c = Repub::Epub::Container.new
    s = c.to_xml
    doc = Nokogiri::XML.parse(s)
    assert_not_nil(doc.at('rootfile'))
    assert_equal('content.opf', doc.at('rootfile')['full-path'])
    assert_equal('application/oebps-package+xml', doc.at('rootfile')['media-type'])
  end
end
