module Repub
  class App
    module Profile

      PROFILE_KEYS = %w[css helper metadata selectors].map(&:to_sym)
      
      def load_profile(name = nil)
        name ||= 'Default'
        profile = Profile.new
        PROFILE_KEYS.each { |key| options[key] = profile[name][key] }
        profile.save
      end
      
      def write_profile(name = nil)
        name ||= 'Default'
        profile = Profile.new
        PROFILE_KEYS.map(&:to_sym).each { |key| profile[name][key] = options[key] }
        profile.save
      end
      
      class Profile
        def initialize
          @profiles = YAML.load_file(Profile.path)
        rescue
          @profiles = {}
        end
        
        def self.path
          File.join(App.data_path, 'profiles')
        end
        
        def [](name)
          @profiles[name] ||= {}
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