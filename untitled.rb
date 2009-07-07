#!/usr/bin/env ruby

module Filter
  
  def self.included(base)
    
    (class << base; self; end).instance_eval do

      attr_reader :filters

      define_method(:filter) do |name, options, &block|
        @filters ||= {}
        role = options[:role]
        raise 'Filter should have a role' unless role
        @filters[role] ||= []
        @filters[role] << {:name => name, :proc => Proc.new(&block) }
      end
    end
  end
  
  def apply_filters (role, input)
    role_filters.inject(input) { |s, filter| p s; filter[:proc].call(s) }
  end
end

class FilterTest
  include Filter
  
  filter :filter_1, :role => :file do |s|
    s.upcase
  end
end

f = FilterTest.new
p f.apply_filters('hi there')
