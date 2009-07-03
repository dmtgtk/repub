require 'test/unit'
require 'repub'
require 'repub/app'

class TestFetcher < Test::Unit::TestCase
  
  include Repub::App::Fetcher
  attr_reader :options
  
  def test_fetcher
    @options = {
      :url            => 'http://repub.rubyforge.org/',
      :helper         => 'wget'
    }
    assert_nothing_raised do
      cache = fetch
      #p cache
      assert_equal('http://repub.rubyforge.org/', cache.url)
      assert_equal('4a14536d6beb8eb74767b4c3e54d4e855eee5642', cache.name)
      assert(cache.path.include?('.repub/cache/4a14536d6beb8eb74767b4c3e54d4e855eee5642'))
      assert(File.exist?(File.join(cache.path, cache.assets[:documents][0])))
    end
  end

  def test_fetcher_fail
    @options = {
      :url            => 'bleh',
      :helper         => 'wget'
    }
   assert_raise(Repub::App::FetcherException) do
     cache = fetch
     #p cache
   end
  end

end
