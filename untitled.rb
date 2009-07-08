#!/usr/bin/env ruby

module Filter
  
  def self.included(base)
    (class << base; self; end).instance_eval do
      define_method(:filter) do |name, &block|
        @filters ||= []
        @filters << {:name => name, :proc => Proc.new(&block) }
      end
      attr_reader :filters
      attr_reader :options
    end
    base.extend(ClassMethods)
  end
  
  def options
    self.class.options
  end
  
  module ClassMethods
    def apply_filters(input, options = nil)
      @options = options
      @filters.inject(input) { |input, filter| filter[:proc].call(input) }
    end
  end
end

class FilterTest
  include Filter
  
  filter :filter_1 do |s|
    p options
    s.upcase
  end
  
  filter :filter_2 do |s|
    "++ #{s} --"
  end
end

p FilterTest.apply_filters('hi there')
