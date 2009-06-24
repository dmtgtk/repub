require 'test/unit'
require "repub"
require 'repub/app'

class TestRepub < Test::Unit::TestCase
  include Repub::App::Logger
  attr_reader :options
  
  def setup
    @options = {
      :verbosity => LOGGER_NORMAL
    }
    @out = String.new
    class << @out
      def puts(value)
        self << value.to_s
      end
    end
    @err = String.new
    class << @err
      def puts(value)
        self << value.to_s
      end
    end
    @log = nil
  end
  
  # Long comment text
  #
  def test_create
    assert_not_nil(log)
  end
  
  def test_output
    l = log(@out, @err)
    l.info "info"
    l.info "more info"
    assert_equal('infomore info', @out)
    l.error "error message"
    assert_equal('error message', @err)
  end
  
  def test_level
    # TODO 
    flunk("todo")
  end
end