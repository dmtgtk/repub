require 'delegate'
require 'yaml'

module Repub
  class App
    module Profile

      PROFILE_KEYS = %w[css encoding fixup helper metadata remove rx selectors].map {|k| k.to_sym}
      
      def load_profile(name = nil)
        name ||= 'default'
        profile = Profile.new
        profile[name] ||= {}
        PROFILE_KEYS.each { |key| options[key] = profile[name][key] if profile[name][key] }
        profile.save
        profile[name]
      end
      
      def write_profile(name = nil)
        name ||= 'default'
        profile = Profile.new
        profile[name] ||= {}
        PROFILE_KEYS.each { |key| profile[name][key] = options[key] }
        profile.save
        profile[name]
      end
      
      def dump_profile(name = nil)
        name ||= 'default'
        profile = Profile.new
        if p = profile[name]
          keys = p.keys.map{|k| k.to_s }.sort.map{|k| k.to_sym }
          keys.each do |key|
            val = p[key]
            next if val.nil? || (val.respond_to?(:empty?) && val.empty?)
            case key
            when :selectors
              printf("%4s%-6s\n", '', key)
              selector_keys = val.keys.map{|k| k.to_s }.sort.map{|k| k.to_sym }
              selector_keys.each { |sk| printf("%8s%-12s %s\n", '', sk, val[sk]) }
            when :remove
              printf("%4s%-6s\n", '', key)
              val.each { |rk| printf("%20s %s\n", '', rk) }
            when :rx
              printf("%4s%-6s\n", '', key)
              val.each { |rk| printf("%20s %s\n", '', rk) }
            when :metadata
              printf("%4s%-6s\n", '', key)
              metadata_keys = val.keys.map{|k| k.to_s }.sort.map{|k| k.to_sym }
              metadata_keys.each { |mk| printf("%8s%-12s %s\n", '', mk, val[mk]) }
            else
              printf("%4s%-16s %s\n", '', key, val)
            end
          end
        end
      end
      
      def list_profiles
        profile = Profile.new
        if profile.empty?
          puts "No saved profiles."
        else
          profile.keys.sort.each do |name|
            puts "#{name}:"
            dump_profile(name)
          end
        end
      end
      
      class Profile < DelegateClass(Hash)
        def initialize
          @profiles = YAML.load_file(Profile.path)
        rescue
        ensure
          @profiles ||= {}
          super(@profiles)
        end
        
        def self.path
          File.join(App.data_path, 'profiles')
        end
        
        def save
          File.open(Profile.path, 'w') do |f|
            YAML.dump(@profiles, f)
          end
        end
      end

    end
  end
end
