require 'test/unit'
require 'rubygems'
require 'nokogiri'
require 'repub/epub'

class TestToc < Test::Unit::TestCase
  def test_toc_create
    ncx = Repub::Epub::NCX.new('some-ncx')
    s = ncx.to_xml
    #p s
    doc = Nokogiri::XML.parse(s)
    assert_equal('some-ncx', doc.at("//xmlns:meta[@name='dtb:uid']")['content'])
    assert_equal('1', doc.at("//xmlns:meta[@name='dtb:depth']")['content'])
    assert_equal('0', doc.at("//xmlns:meta[@name='dtb:totalPageCount']")['content'])
    assert_equal('0', doc.at("//xmlns:meta[@name='dtb:maxPageNumber']")['content'])
    assert_equal('Untitled', doc.at("//xmlns:docTitle/xmlns:text").inner_text)
    assert_not_nil(doc.at('//xmlns:navMap'))
  end
  
  def test_nav_map
    ncx = Repub::Epub::NCX.new('some-ncx')
    ncx.nav_map.points << Repub::Epub::NCX::NavPoint.new('Intro', 'intro.html')
    ncx.nav_map.points << Repub::Epub::NCX::NavPoint.new('Chapter 1', 'chapter-1.html')
    ncx.nav_map.points << Repub::Epub::NCX::NavPoint.new('Chapter 2', 'chapter-2.html')
    ncx.nav_map.points[2].points << Repub::Epub::NCX::NavPoint.new('Chapter 2-1', 'chapter-2-1.html')
    ncx.nav_map.points << Repub::Epub::NCX::NavPoint.new('Glossary', 'glossary.html')
    ncx.nav_map.points[1].points << Repub::Epub::NCX::NavPoint.new('Chapter 1-1', 'chapter-1-1.html')
    ncx.nav_map.points[1].points << Repub::Epub::NCX::NavPoint.new('Chapter 1-2', 'chapter-1-2.html')
    s = ncx.to_xml
    #p s
    doc = Nokogiri::XML.parse(s)
    assert_equal(4, doc.xpath('//xmlns:navMap/xmlns:navPoint').size)
    assert_equal('2', doc.at("//xmlns:meta[@name='dtb:depth']")['content'])
    assert_equal('1', doc.at('//xmlns:navMap/xmlns:navPoint[position()=1]')['playOrder'])
    assert_equal('2', doc.at('//xmlns:navMap/xmlns:navPoint[position()=2]')['playOrder'])
    assert_equal('3', doc.at('//xmlns:navMap/xmlns:navPoint[position()=2]/xmlns:navPoint[position()=1]')['playOrder'])
    assert_equal('5', doc.at('//xmlns:navMap/xmlns:navPoint[position()=3]')['playOrder'])
    assert_equal('2', doc.at('//xmlns:navMap/xmlns:navPoint[position()=2]')['id'])
    assert_equal('Chapter 1', doc.at('//xmlns:navMap/xmlns:navPoint[position()=2]/xmlns:navLabel/xmlns:text').inner_text)
    assert_equal('chapter-1.html', doc.at('//xmlns:navMap/xmlns:navPoint[position()=2]/xmlns:content')['src'])
    assert_equal(7, doc.xpath('//xmlns:navMap//xmlns:navPoint').size)
  end
end
