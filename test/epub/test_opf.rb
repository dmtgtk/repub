require 'test/unit'
require 'rubygems'
require 'nokogiri'
require 'repub/epub'

class TestContent < Test::Unit::TestCase
  def test_create
    opf = Repub::Epub::OPF.new('some-opf')
    s = opf.to_xml
    doc = Nokogiri::XML.parse(s)
    #p doc

    metadata = doc.at('metadata')
    assert_not_nil(metadata)
    assert_equal('some-opf', metadata.xpath('dc:identifier', 'xmlns:dc' => "http://purl.org/dc/elements/1.1/").inner_text)
    assert_equal('Untitled', metadata.xpath('dc:title', 'xmlns:dc' => "http://purl.org/dc/elements/1.1/").inner_text)
    assert_equal('en', metadata.xpath('dc:language', 'xmlns:dc' => "http://purl.org/dc/elements/1.1/").inner_text)
    assert_equal(Date.today.to_s, metadata.xpath('dc:date', 'xmlns:dc' => "http://purl.org/dc/elements/1.1/").inner_text)
  end

  def test_manifest_create
    opf = Repub::Epub::OPF.new('some-opf')
    opf << Repub::Epub::NCX.new('some-ncx')
    s = opf.to_xml
    doc = Nokogiri::XML.parse(s)
    #p doc
  
    manifest = doc.at('manifest')
    assert_not_nil(manifest)
    assert_equal(1, manifest.children.size)
    assert_equal('0', manifest.at('item[@href="toc.ncx"]')['id'])
    assert_not_nil(doc.at('spine'))
    assert_equal(0, doc.xpath('spine/item').size)
  end

  def test_manifest_and_spine_items
    opf = Repub::Epub::OPF.new('some-opf')
    opf << 'style.css'
    opf << 'more-style.css'
    opf << ' logo.jpg '
    opf << 'intro.html'
    opf << ' image.png'
    opf << 'picture.jpeg     '
    opf << 'chapter-1.html'
    opf << 'glossary.html'
    s = opf.to_xml
    doc = Nokogiri::HTML(s)
    #p doc
  
    manifest = doc.at('manifest')
    assert_not_nil(manifest)
    assert_equal(2, manifest.xpath('item[@media-type="text/css"]').size)
    assert_equal(2, manifest.search('item[@media-type="image/jpeg"]').size)
    assert_equal(1, manifest.search('item[@media-type="image/png"]').size)
    
    spine = doc.at('spine')
    assert_equal(3, spine.search('itemref').size)
    assert_equal('3', spine.at('./itemref[position()=1]')['idref'])
    assert_equal('7', spine.at('./itemref[position()=3]')['idref'])
  end
end
