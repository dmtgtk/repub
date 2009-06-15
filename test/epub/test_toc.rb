require 'test/unit'
require 'rubygems'
require 'hpricot'
require 'repub/epub'

class TestToc < Test::Unit::TestCase
  def test_toc_create
    x = Repub::Epub::Toc.new('some-name')
    s = x.to_xml
    #puts s
    doc = Hpricot(s)
    # TODO 
  end
  
  def test_toc
    x = Repub::Epub::Toc.new('some-name')
    p0 = x.nav_map.add_nav_point('Intro', 'intro.html')
    p1 = x.nav_map.add_nav_point('Chapter 1', 'chapter-1.html')
    p2 = x.nav_map.add_nav_point('Chapter 2', 'chapter-2.html')
    p21 = p2.add_nav_point('Chapter 2-1', 'chapter-2-1.html')
    pg = x.nav_map.add_nav_point('Glossary', 'glossary.html')
    p11 = p1.add_nav_point('Chapter 1-1', 'chapter-1-1.html')
    p12 = p1.add_nav_point('Chapter 1-2', 'chapter-1-2.html')
    s = x.to_xml
    #puts s
    doc = Hpricot(s)
    # TODO 
  end
end
