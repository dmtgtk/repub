require "test/unit"

require 'repub'
require 'repub/app'

class TestFilter < Test::Unit::TestCase
  include Repub::App::Filter
  
  filter :filter_1 do |s|
    log.info 'in filter_1'
    s.upcase
  end
  
  filter :filter_2 do |s|
    log.info 'in filter_2'
    "++ #{s} --"
  end
  
  filter :filter_3 do |s|
    log.info 'in filter_3'
    s.gsub(/\s/, '|')
  end
  
  def test_case_name
    res = TestFilter.apply_filters('klaatu barada nikto')
    assert_equal('++|KLAATU|BARADA|NIKTO|--', res)
  end
end