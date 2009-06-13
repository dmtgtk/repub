require 'test/unit'
require 'repub'

class TestParser < Test::Unit::TestCase
  
  def test_parser
    cache = Repub::Fetcher.get('http://www.berzinarchives.com/web/x/prn/p.html_1614431902.html')
    parser = Repub::Parser.new(cache)
    parser.parse
    assert_equal('f963050ead9ee7775a4155e13743d47bc851d5d8', parser.uid)
    puts "UID: #{parser.uid}"
    assert_equal('A Survey of Tibetan History', parser.title)
    puts "Title: #{parser.title}"
    assert_equal('Reading notes taken by Alexander Berzin fromTsepon, W. D. Shakabpa, Tibet: A Political History. New Haven, Yale University Press, 1967', parser.subtitle)
    puts "Subtitle: #{parser.subtitle}"
    puts parser.toc
    assert_equal(51, parser.toc.size)
    puts "TOC: (#{parser.toc.size} items)"
  end

end
