require 'test/unit'
require 'repub'

class TestFetcher < Test::Unit::TestCase
  
  def test_fetcher
    assert_nothing_raised do
      cache = Repub::Fetcher.get('http://www.berzinarchives.com/web/x/prn/p.html_1614431902.html')
      p cache
      assert_equal('http://www.berzinarchives.com/web/x/prn/p.html_1614431902.html', cache.url)
      assert(cache.path.include?('.repub/cache/f963050ead9ee7775a4155e13743d47bc851d5d8'))
      assert_equal('f963050ead9ee7775a4155e13743d47bc851d5d8', cache.name)
      # assert(File.exist?(File.join(f.asset_root, f.asset_name)), "Fetch failed.")
    end
  end

  def test_fetcher_fail
    assert_raise(Repub::FetcherException) do
      cache = Repub::Fetcher.get('non-existing')
      p cache
    end
  end

end
