require 'test/unit'
require 'repub'
require 'repub/app'

class TestFetcher < Test::Unit::TestCase
  
  include Repub::App::Fetcher
  attr_reader :options
  
  def test_fetcher
    @options = {
      :url            => 'http://www.berzinarchives.com/web/x/prn/p.html_1614431902.html',
      :helper         => 'wget'
    }
    assert_nothing_raised do
      cache = fetch
      #p cache
      assert_equal('http://www.berzinarchives.com/web/x/prn/p.html_1614431902.html', cache.url)
      assert(cache.path.include?('.repub/cache/f963050ead9ee7775a4155e13743d47bc851d5d8'))
      assert_equal('f963050ead9ee7775a4155e13743d47bc851d5d8', cache.name)
      # assert(File.exist?(File.join(f.asset_root, f.asset_name)), "Fetch failed.")
    end
  end

  def test_fetcher_fail
    @options = {
      :url            => 'not-existing',
      :helper         => 'wget'
    }
   assert_raise(Repub::App::FetcherException) do
     cache = fetch
     #p cache
   end
  end

end
