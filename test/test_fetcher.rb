require 'test/unit'
require 'repub'
require 'repub/app'

class TestFetcher < Test::Unit::TestCase
  
  include Repub::App::Fetcher
  attr_reader :options
  
  def setup
    @url = 'file://' + File.expand_path(File.join(File.dirname(__FILE__), 'data/test.html'))
    @options = {
      :url            => @url,
      # NOTE: cannot test with wget because it doesn't support file:// schema
      :helper         => 'httrack'
    }
    Cache.cleanup
  end
  
  def teardown
    Cache.cleanup
  end
  
  def test_cache_cleanup
    Cache.cleanup
    assert_equal(0, Dir.glob(Cache.root + '/**').size)
    cache = fetch
    assert_equal(1, Dir.glob(Cache.root + '/**').size)
    assert_equal(3, Dir.glob(cache.path + '/*').size)
    Cache.cleanup
    assert_equal(0, Dir.glob(Cache.root + '/**').size)
  end
  
  def test_fetcher
    cache = fetch
    assert_equal(@url, cache.url)
    assert_equal('8b8d358cf1ada41d4fee885a47530296528dc235', cache.name)
    assert(cache.path.include?('.repub/cache/8b8d358cf1ada41d4fee885a47530296528dc235'))
    assert(File.exist?(File.join(cache.path, cache.assets[:documents][0])))
    assert_equal(1, cache.assets[:documents].size)
    assert_equal('test.html', cache.assets[:documents][0])
    assert(File.exist?(File.join(cache.path, cache.assets[:stylesheets][0])))
    assert_equal(1, cache.assets[:stylesheets].size)
    assert_equal('test.css', cache.assets[:stylesheets][0])
    assert(File.exist?(File.join(cache.path, cache.assets[:images][0])))
    assert_equal(1, cache.assets[:images].size)
    assert_equal('invisiblellama.png', cache.assets[:images][0])
  end

  def test_fetcher_fail
    # empty url
    @options[:url] = nil
    assert_raise(Repub::App::FetcherException) do
      cache = fetch
    end
    @options[:url] = ''
    assert_raise(Repub::App::FetcherException) do
      cache = fetch
    end
    # empty download helper
    @options[:url] = 'bleh'
    @options[:helper] = nil
    assert_raise(Repub::App::FetcherException) do
      cache = fetch
    end
    @options[:helper] = ''
    assert_raise(Repub::App::FetcherException) do
      cache = fetch
    end
    # unknown download helper
    @options[:helper] = 'blah'
    assert_raise(Repub::App::FetcherException) do
      cache = fetch
    end
    # unresolvable url
    @options[:helper] = 'wget'
    assert_raise(Repub::App::FetcherException) do
      cache = fetch
    end
    @options[:helper] = 'httrack'
    assert_raise(Repub::App::FetcherException) do
      cache = fetch
    end
  end
  
  def test_file_encoding_conversion
    cache = fetch
    assert_equal('test.html', cache.assets[:documents][0])
    doc = cache.assets[:documents][0]
    s_orig = IO.read(File.join(cache.path, doc))
    encoding = UniversalDetector.chardet(s_orig)['encoding']
    s_converted = Iconv.conv('utf-8', encoding, s_orig)
    assert_equal(s_orig, s_converted)
  end
end
