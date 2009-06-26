require 'test/unit'
require 'repub'
require 'repub/app'

class TestParser < Test::Unit::TestCase
  
  include Repub::App::Fetcher
  include Repub::App::Parser
  attr_reader :options

  def test_parser
    @options = {
      :url            => 'http://www.berzinarchives.com/web/x/prn/p.html_1614431902.html',
      :helper         => 'wget'
      # :selectors      => {
          #   :title        => '//h1',
          #   :toc          => '//div.toc/ul',
          #   :toc_item     => '/li',
          #   :toc_section  => '/ul'
          # }
        }
    parser = parse(fetch)
    assert_equal('f963050ead9ee7775a4155e13743d47bc851d5d8', parser.uid)
    puts "UID: #{parser.uid}"
    assert_equal('A Survey of Tibetan History', parser.title)
    puts "Title: #{parser.title}"
    #puts parser.toc
    assert_equal(4, parser.toc.size)
    puts "TOC: (#{parser.toc.size} items)"
  end

end
