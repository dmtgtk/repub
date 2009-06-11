require 'test/unit'
require 'rubygems'
require 'hpricot'
require 'repub'

class TestContainer < Test::Unit::TestCase
  def test_container_create
    c = Repub::Epub::Container.new
    s = c.to_xml
    doc = Hpricot(s)
    puts s
    assert_not_nil(doc.search('rootfile'))
  end
end
