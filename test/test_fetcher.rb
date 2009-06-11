require 'test/unit'
require 'repub'

class TestFetcher < Test::Unit::TestCase
  
  def test_fetcher
    assert_nothing_raised do
      cache = Repub::Fetcher.get('http://www.berzinarchives.com/web/x/prn/p.html_272733222.html')
      p cache
      # assert_equal('http://www.berzinarchives.com/web/x/prn/p.html_272733222.html', cache.url)
      # assert_equal('p.html_272733222.html', f.asset_name)
      # assert_equal('/Users/dg/Projects/repub/tmp/p.html_272733222', f.asset_root)
      # assert(File.exist?(File.join(f.asset_root, f.asset_name)), "Fetch failed.")
    end
  end

  # def test_fetcher_fail
  #   f = Repub::Fetcher.new('http://www.berzinarchives.com/web/x/prn/doesnt-exist.html', 'tmp')
  #   assert_raise(Repub::FetcherException) do
  #     f.fetch
  #   end
  # end

end
