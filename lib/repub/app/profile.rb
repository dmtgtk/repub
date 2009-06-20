require 'delegate'

module Repub
  class App
    module Profile

      PROFILE_KEYS = %w[css encoding helper metadata selectors].map(&:to_sym)
      
      def load_profile(name = nil)
        name ||= 'Default'
        profile = Profile.new
        profile[name] ||= {}
        PROFILE_KEYS.each { |key| options[key] = profile[name][key] if profile[name][key] }
        profile.save
        profile[name]
      end
      
      def write_profile(name = nil)
        name ||= 'Default'
        profile = Profile.new
        profile[name] ||= {}
        PROFILE_KEYS.each { |key| profile[name][key] = options[key] }
        profile.save
        profile[name]
      end
      
      def list_profiles
        profile = Profile.new
        if profile.empty?
          puts "No saved profiles."
        else
          puts "Saved profiles:"
          profile.each_pair do |k, v|
            puts "    #{k}:"
            v.each_pair do |pk, pv|
              printf("%12s: %s", pk, pv)
            end
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