require 'delegate'
require 'test/unit'
require 'repub'
require 'repub/app'

class TestRepub < Test::Unit::TestCase
  include Repub::App::Logger
  attr_reader :options
  
  class FakeStringStream < DelegateClass(String)
    def initialize
      @str = String.new
      super(@str)
    end
    def puts(value)
      @str << value.to_s
    end
  end
  
  def setup
    @options = {
      :verbosity => LOGGER_NORMAL
    }
    @out = FakeStringStream.new
    @err = FakeStringStream.new
  end
  
  def changed(stream, &blk)
    klone = stream.clone
    yield
    klone.to_s != stream.to_s
  end
  
  def assert_out(&blk);    assert  changed(@out, &blk);  end
  def assert_no_out(&blk); assert !changed(@out, &blk);  end
  def assert_err(&blk);    assert  changed(@err, &blk);  end
  def assert_no_err(&blk); assert !changed(@err, &blk);  end
  
  def test_create
    assert_not_nil(log)
  end
  
  def test_streams
    l = log(@out, @err)
    l.info "info"
    l.info "more info"
    assert_equal('infomore info', @out)
    l.error "error message"
    assert_equal('error message', @err)
  end
  
  def test_verbose_level
    l = log(@out, @err)
    l.level = LOGGER_VERBOSE
    assert_out { l.debug "debug" }
    assert_out { l.info "info" }
    assert_err { l.error "error" }
  end
  
  def test_normal_level
    l = log(@out, @err)
    l.level = LOGGER_NORMAL
    assert_no_out { l.debug "debug" }
    assert_out { l.info "info" }
    assert_err { l.error "error" }
  end
  
  def test_quiet_level
    l = log(@out, @err)
    l.level = LOGGER_QUIET
    assert_no_out { l.debug "debug" }
    assert_no_out { l.info "info" }
    assert_err { l.error "error" }
  end
  
  def test_fatal
    l = log(@out, @err)
    l.level = LOGGER_QUIET
    assert_raise(SystemExit) { l.fatal "fatal" }
    begin
      assert_err { l.fatal "bye" }
    rescue SystemExit
    end
  end
end