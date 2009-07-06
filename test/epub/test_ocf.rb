require 'test/unit'
require 'rubygems'
require 'nokogiri'
require 'repub/epub'

class TestContainer < Test::Unit::TestCase
  def test_container_create
    container = Repub::Epub::OCF.new
    container << 'test.html'
    container << Repub::Epub::OPF.new('12345')
    s = container.to_xml
    #p s
    doc = Nokogiri::XML.parse(s)
    assert_not_nil(doc.at('rootfile'))
    assert_equal('test.html', doc.at('rootfile[1]')['full-path'])
    assert_equal('application/xhtml+xml', doc.at('rootfile[1]')['media-type'])
    assert_equal('package.opf', doc.at('rootfile[2]')['full-path'])
    assert_equal('application/oebps-package+xml', doc.at('rootfile[2]')['media-type'])
  end
  
  def test_container_create_fail
    assert_raise(RuntimeError) do
      # unknown mime type
      container = Repub::Epub::OCF.new
      container << 'blah.blah'
    end
  end
end
