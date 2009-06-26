require 'delegate'
require 'test/unit'
require 'repub'
require 'repub/app'

class TestRepub < Test::Unit::TestCase
  include Repub::App::Logger
  
  class FakeStringStream < DelegateClass(String)
    def initialize
      @str = String.new
      super(@str)
    end
    def puts(value)
      @str << value.to_s
    end
    def changed
      klone = self.clone
      yield
      klone.to_s != self.to_s
    end
  end
  
  def setup
    log.level = LOGGER_NORMAL
    log.stdout = @out = FakeStringStream.new
    log.stderr = @err = FakeStringStream.new
  end
  
  def assert_out(&blk);    assert  @out.changed(&blk);  end
  def assert_no_out(&blk); assert !@out.changed(&blk);  end
  def assert_err(&blk);    assert  @err.changed(&blk);  end
  def assert_no_err(&blk); assert !@err.changed(&blk);  end
  
  def test_create
    assert_not_nil(log)
  end
  
  def test_streams
    log.info "info"
    log.info "more info"
    assert_equal('infomore info', @out)
    log.error "error message"
    assert_equal('error message', @err)
  end
  
  def test_verbose_level
    log.level = LOGGER_VERBOSE
    assert_out { log.debug "debug" }
    assert_out { log.info "info" }
    assert_err { log.error "error" }
  end
  
  def test_normal_level
    log.level = LOGGER_NORMAL
    assert_no_out { log.debug "debug" }
    assert_out { log.info "info" }
    assert_err { log.error "error" }
  end
  
  def test_quiet_level
    log.level = LOGGER_QUIET
    assert_no_out { log.debug "debug" }
    assert_no_out { log.info "info" }
    assert_err { log.error "error" }
  end
  
  def test_fatal
    log.level = LOGGER_QUIET
    assert_raise(SystemExit) { log.fatal "fatal" }
    begin
      assert_err { log.fatal "bye" }
    rescue SystemExit
    end
  end
end