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
    p doc
  
    # manifest was created
    assert_not_nil(doc.search('manifest'))
    # has 2 stylesheets
    assert_equal(2, doc.search('manifest/item[@media-type = "text/css"]').size)
    # and 2 jpegs
    assert_equal(2, doc.search('manifest/item[@media-type = "image/jpeg"]').size)
    # and 1 png
    assert_equal(1, doc.search('manifest/item[@media-type = "image/png"]').size)
    # spine was created
    assert_not_nil(doc.search('spine'))
    # and has 3 html items
    assert_equal(3, doc.search('spine/itemref').size)
    # check that order is as inserted and ids are correct
    assert_equal('intro', doc.search('spine/itemref')[0]['idref'])
    assert_equal('glossary', doc.search('spine/itemref')[2]['idref'])
  end
end
