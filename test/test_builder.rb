require 'test/unit'
require 'repub'
require 'repub/app'

class TestBuilder < Test::Unit::TestCase
  include Repub::App::Fetcher
  include Repub::App::Parser
  include Repub::App::Builder
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
      },
      # do not delete temp folder
      :browser        => true
    }
    Cache.cleanup
  end
  
  def teardown
    Cache.cleanup
  end
  
  def test_builder
    builder = build(parse(fetch))
    doc_path = builder.document_path
    assert(doc_path.include?('test.html'))
    doc_text = IO.read(doc_path)
    # doctype was added
    assert(doc_text =~ /^<!DOCTYPE/)
    doc = Nokogiri::HTML.parse(doc_text, nil, 'UTF-8')
    # encoding was set to utf-8
    doc.xpath('//head/meta[@http-equiv="Content-Type"]').each do |el|
      assert_equal('text/html; charset=utf-8', el['content'].downcase)
    end
  end
  
  def test_rx
    @options[:rx] = ['/Chapter/Retpahc/', '/<h1>/<h2>/', '/<\/h1>/<\/h2>/', '/\s?[Ll]orem\s+//']
    builder = build(parse(fetch))
    doc_path = builder.document_path
    doc_text = IO.read(doc_path)
    #p doc_text
    assert(doc_text =~ /Retpahc/ && doc_text !~ /Chapter/)
    assert(doc_text =~ /<h2>/ && doc_text !~ /<h1>/)
    assert(doc_text =~ /<\/h2>/ && doc_text !~ /<\/h1>/)
    assert(doc_text !~ /[Ll]orem/)
  end
  
  def test_custom_css
    @options[:css] = File.expand_path(File.join(File.dirname(__FILE__), 'data/custom.css'))
    builder = build(parse(fetch))
    doc_path = builder.document_path
    doc_text = IO.read(doc_path)
    #p doc_text
    doc = Nokogiri::HTML.parse(doc_text, nil, 'UTF-8')
    links = doc.xpath('//head/link[@rel="stylesheet"]')
    # we have single link
    assert_equal(1, links.size)
    # referencing custom.css
    assert_equal('custom.css', links[0]['href'])
    head_last_child = doc.at('//head/*[last()]')
    # and it is head's last child
    assert_equal(links[0], head_last_child)
  end
  
  def test_removing_styles
    @options[:css] = '-'
    builder = build(parse(fetch))
    doc_path = builder.document_path
    doc_text = IO.read(doc_path)
    p doc_text
    doc = Nokogiri::HTML.parse(doc_text, nil, 'UTF-8')
    links = doc.xpath('//head/link[@rel="stylesheet"]')
    # no stylesheet links
    assert_equal(0, links.size)
    styles = doc.xpath('//head/style')
    # no <style> elements
    assert_equal(0, styles.size)
  end
  
  def test_inserting_elements_after
    selector1 = '//ul'
    fragment1 = Nokogiri::HTML.fragment('<p>blah</p>')
    selector2 = '//p[last()]'
    fragment2 = Nokogiri::HTML.fragment('<span>bleh</span>')
    @options[:after] = [{ selector1 => fragment1}, {selector2 => fragment2}]
    builder = build(parse(fetch))
    doc_path = builder.document_path
    doc_text = IO.read(doc_path)
    #p doc_text
    doc = Nokogiri::HTML.parse(doc_text, nil, 'UTF-8')
    p doc
    assert_equal(fragment1.to_html, doc.xpath(selector1).first.next_sibling.to_html)
  end
end
