require 'test/unit'
require 'rubygems'
require 'nokogiri'
require 'repub/epub'

class TestContent < Test::Unit::TestCase
  def test_create
    x = Repub::Epub::Content.new('some-name')
    s = x.to_xml
    doc = Nokogiri::XML.parse(s)
    #p doc

    metadata = doc.at('metadata')
    assert_not_nil(metadata)
    assert_equal('some-name', metadata.xpath('dc:identifier', 'xmlns:dc' => "http://purl.org/dc/elements/1.1/").inner_text)
    assert_equal('Untitled', metadata.xpath('dc:title', 'xmlns:dc' => "http://purl.org/dc/elements/1.1/").inner_text)
    assert_equal('en', metadata.xpath('dc:language', 'xmlns:dc' => "http://purl.org/dc/elements/1.1/").inner_text)
    assert_equal(Date.today.to_s, metadata.xpath('dc:date', 'xmlns:dc' => "http://purl.org/dc/elements/1.1/").inner_text)
  end

  def test_manifest_create
    x = Repub::Epub::Content.new('some-name')
    s = x.to_xml
    doc = Nokogiri::XML.parse(s)
    #p doc
  
    manifest = doc.at('manifest')
    assert_not_nil(manifest)
    assert_equal(1, manifest.children.size)
    assert_equal('ncx', manifest.at('item')['id'])
    assert_not_nil(doc.at('spine'))
    assert_equal(0, doc.xpath('spine/item').size)
  end

  def test_manifest_items
    x = Repub::Epub::Content.new('some-name')
    x.add_item 'style.css'
    x.add_item 'more-style.css'
    x.add_item ' logo.jpg '
    x.add_item ' image.png'
    x.add_item 'picture.jpeg     '
    x.add_item 'intro.html', 'intro'
    x.add_item 'chapter-1.html'
    x.add_item 'glossary.html', 'glossary'
    s = x.to_xml
    doc = Nokogiri::HTML(s)
    #p doc
  
    manifest = doc.at('manifest')
    assert_not_nil(manifest)
    assert_equal(2, manifest.xpath('item[@media-type="text/css"]').size)
    assert_equal(2, manifest.search('item[@media-type="image/jpeg"]').size)
    assert_equal(1, manifest.search('item[@media-type="image/png"]').size)
    
    spine = doc.at('spine')
    assert_equal(3, spine.search('itemref').size)
    assert_equal('intro', spine.at('./itemref[position()=1]')['idref'])
    assert_equal('glossary', spine.at('./itemref[position()=3]')['idref'])
  end
end
