require 'test/unit'
require 'rubygems'
require 'nokogiri'
require 'repub/epub'

class TestContent < Test::Unit::TestCase
  def test_manifest_create
    x = Repub::Epub::Content.new('some-name')
    s = x.to_xml
    #puts s
    doc = Nokogiri::HTML(s)
  
    # manifest was created
    assert_not_nil(doc.search('manifest'))
    # has exactly one item
    assert_equal(1, doc.search('manifest/item').size)
    # and item is ncx
    assert_equal('ncx', doc.search('manifest/item')[0][:id])
    # spine was created
    assert_not_nil(doc.search('spine'))
    # and is empty
    assert_equal(0, doc.search('spine/item').size)
  end

  def test_manifest
    x = Repub::Epub::Content.new('some-name')
    x.add_page_template
    x.add_stylesheet 'style.css'
    x.add_stylesheet 'more-style.css'
    x.add_image ' logo.jpg '
    x.add_image ' image.png'
    x.add_image 'picture.jpeg     '
    x.add_document 'intro.html', 'intro'
    x.add_document 'chapter-1.html'
    x.add_document 'glossary.html', 'glossary'
    s = x.to_xml
    #puts s
    doc = Nokogiri::HTML(s)
  
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
