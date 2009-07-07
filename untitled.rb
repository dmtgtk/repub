#!/usr/bin/env ruby

module Filter
  
  def self.included(base)
    (class << base; self; end).instance_eval do
      attr_reader :filters
      define_method(:filter) do |name, &block|
        @filters ||= []
        @filters << {:name => name, :proc => Proc.new(&block) }
      end
    end
  end
  
  def apply_filters(input)
    self.class.filters.inject(input) { |input, filter| filter[:proc].call(input) }
  end
end

class FilterTest
  include Filter
  
  filter :filter_1 do |s|
    s.upcase
  end
  
  filter :filter_2 do |s|
    "++ #{s} --"
  end
end

f = FilterTest.new
p f.apply_filters('hi there')
