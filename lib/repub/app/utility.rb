require 'tmpdir'

# Convenience method to avoid long ifs with nil? and empty?
# If receiver is nil or empty? is _true_, returns _value_
# Otherwise, returns self
#
class Object
  def if_blank(value)
    self.nil? || self.empty? ? value : self
  end
end

# Windows still has one-click installer based on Ruby 1.8.6
# Add this for compatibility (from Ruby 1.8.7 tmpdir.rb)
#
if not Dir.respond_to? :mktmpdir
  class << Dir
    def mktmpdir(prefix_suffix=nil, tmpdir=nil)
      case prefix_suffix
      when nil
        prefix = "d"
        suffix = ""
      when String
        prefix = prefix_suffix
        suffix = ""
      when Array
        prefix = prefix_suffix[0]
        suffix = prefix_suffix[1]
      else
        raise ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
      end
      tmpdir ||= Dir.tmpdir
      t = Time.now.strftime("%Y%m%d")
      n = nil
      begin
        path = "#{tmpdir}/#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}"
        path << "-#{n}" if n
        path << suffix
        Dir.mkdir(path, 0700)
      rescue Errno::EEXIST
        n ||= 0
        n += 1
        retry
      end
    
      if block_given?
        begin
          yield path
        ensure
          FileUtils.remove_entry_secure path
        end
      else
        path
      end
    end
  end
end
