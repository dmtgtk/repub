require 'test/unit'
require 'rubygems'
require 'hpricot'
require 'repub'

class TestContent < Test::Unit::TestCase
  def test_manifest_create
    x = Repub::Epub::Content.new('some-name')
    s = x.to_xml
    doc = Hpricot(s)
  
    # manifest was created
    assert_not_nil(doc.search('manifest'))
    # has exactly one item
    assert_equal(1, doc.search('manifest/item').count)
    # and item is ncx
    assert_equal('ncx', doc.search('manifest/item')[0][:id])
    # spine was created
    assert_not_nil(doc.search('spine'))
    # and is empty
    assert_equal(0, doc.search('spine/item').count)
  end

  def test_manifest
    x = Repub::Epub::Content.new('some-name')
    x.add_page_template
    x.add_css 'style.css'
    x.add_css 'more-style.css'
    x.add_img ' logo.jpg '
    x.add_img ' image.png'
    x.add_img 'picture.jpeg     '
    x.add_html 'intro.html', 'intro'
    x.add_html 'chapter-1.html'
    x.add_html 'glossary.html', 'glossary'

    s = x.to_xml
    doc = Hpricot(s)
  
    puts s
  
    # manifest was created
    assert_not_nil(doc.search('manifest'))
    # has 2 stylesheets
    assert_equal(2, doc.search('manifest/item[@media-type = "text/css"]').count)
    # and 2 jpegs
    assert_equal(2, doc.search('manifest/item[@media-type = "image/jpeg"]').count)
    # and 1 png
    assert_equal(1, doc.search('manifest/item[@media-type = "image/png"]').count)
    # spine was created
    assert_not_nil(doc.search('spine'))
    # and has 3 html items
    assert_equal(3, doc.search('spine/itemref').count)
    # check that order is as inserted and ids are correct
    assert_equal('intro', doc.search('spine/itemref')[0]['idref'])
    assert_equal('glossary', doc.search('spine/itemref')[2]['idref'])
  end
end
