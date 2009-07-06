require 'test/unit'
require 'repub'
require 'repub/app'

class TestParser < Test::Unit::TestCase
  
  include Repub::App::Fetcher
  include Repub::App::Parser
  attr_reader :options

  def setup
    @url = 'file://' + File.expand_path(File.join(File.dirname(__FILE__), 'data/test.html'))
    @options = {
      :url            => @url,
      # NOTE: cannot test with wget because it doesn't support file:// schema
      :helper         => 'httrack',
      :selectors => {
        :title        => '//h1',
        :toc          => '//ul',
        :toc_item     => './li',
        :toc_section  => './ul'
      }
    }
    Cache.cleanup
  end
  
  def teardown
    Cache.cleanup
  end
  
  def test_parser
    cache = fetch
    parser = parse(cache)
    assert_equal('8b8d358cf1ada41d4fee885a47530296528dc235', parser.uid)
    assert_equal('Lorem Ipsum', parser.title)
    assert_equal(3, parser.toc.size)
    assert_equal('Chapter 1', parser.toc[0].title)
    assert_equal('Chapter 3', parser.toc[2].title)
    assert_equal(2, parser.toc[0].points.size)
    assert_equal('Chapter 1.2', parser.toc[0].points[1].title)
    assert_equal("#{cache.assets[:documents][0]}#c12", parser.toc[0].points[1].src)
  end

end
