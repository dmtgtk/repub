require 'test/unit'
require 'rubygems'
require 'nokogiri'
require 'repub/epub'

class TestToc < Test::Unit::TestCase
  def test_toc_create
    x = Repub::Epub::Toc.new('some-name')
    s = x.to_xml
    doc = Nokogiri::XML.parse(s)
    assert_equal('some-name', doc.at("//xmlns:meta[@name='dtb:uid']")['content'])
    assert_equal('1', doc.at("//xmlns:meta[@name='dtb:depth']")['content'])
    assert_equal('0', doc.at("//xmlns:meta[@name='dtb:totalPageCount']")['content'])
    assert_equal('0', doc.at("//xmlns:meta[@name='dtb:maxPageNumber']")['content'])
    assert_equal('Untitled', doc.at("//xmlns:docTitle/xmlns:text").inner_text)
    assert_not_nil(doc.at('//xmlns:navMap'))
  end
  
  def test_nav_map
    x = Repub::Epub::Toc.new('some-name')
    p0 = x.nav_map.add_nav_point('Intro', 'intro.html')
    p1 = x.nav_map.add_nav_point('Chapter 1', 'chapter-1.html')
    p2 = x.nav_map.add_nav_point('Chapter 2', 'chapter-2.html')
    p21 = p2.add_nav_point('Chapter 2-1', 'chapter-2-1.html')
    pg = x.nav_map.add_nav_point('Glossary', 'glossary.html')
    p11 = p1.add_nav_point('Chapter 1-1', 'chapter-1-1.html')
    p12 = p1.add_nav_point('Chapter 1-2', 'chapter-1-2.html')
    s = x.to_xml
    doc = Nokogiri::XML.parse(s)
    assert_equal(4, doc.xpath('//xmlns:navMap/xmlns:navPoint').size)
    assert_equal('2', doc.at("//xmlns:meta[@name='dtb:depth']")['content'])
    assert_equal('1', doc.at('//xmlns:navMap/xmlns:navPoint[position()=1]')['playOrder'])
    assert_equal('2', doc.at('//xmlns:navMap/xmlns:navPoint[position()=2]')['playOrder'])
    assert_equal('3', doc.at('//xmlns:navMap/xmlns:navPoint[position()=2]/xmlns:navPoint[position()=1]')['playOrder'])
    assert_equal('5', doc.at('//xmlns:navMap/xmlns:navPoint[position()=3]')['playOrder'])
    assert_equal('navPoint-2', doc.at('//xmlns:navMap/xmlns:navPoint[position()=2]')['id'])
    assert_equal('Chapter 1', doc.at('//xmlns:navMap/xmlns:navPoint[position()=2]/xmlns:navLabel/xmlns:text').inner_text)
    assert_equal('chapter-1.html', doc.at('//xmlns:navMap/xmlns:navPoint[position()=2]/xmlns:content')['src'])
    assert_equal(7, doc.xpath('//xmlns:navMap//xmlns:navPoint').size)
  end
end
