require 'test/unit'
require 'repub'

class TestParser < Test::Unit::TestCase
  
  def test_parser
    cache = Repub::Fetcher.get('http://www.berzinarchives.com/web/x/prn/p.html_1614431902.html')
    parser = Repub::Parser.new(cache)
    parser.parse
    pp parser
    # assert_equal('p.html_272733222.epub', p.uid)
    # puts "UID: #{p.uid}"
    # assert_equal('Paraphrase of Advice from an Experienced Old Man', p.title)
    # puts "Title: #{p.title}"
    # assert_equal('(Nyams-myong rgan-po\'i \'bel-gtam yid-\'byung dmar-khrid) Geshe Ngawang Dhargyey written from notes taken by Alexander Berzin from the oral translation by Sharpa Rinpoche Dharamsala, India, September 5 - 12, 1975', p.subtitle)
    # puts "Subtitle: #{p.subtitle}"
    # puts "TOC: (#{p.toc.size} items)"
    # puts p.toc if !p.toc.empty?
    # assert_equal(0, p.toc.size)
  end

end
