module Repub
  module Epub

  class Mimetype
    def self.save(path = 'mimetype')
      File.open(path, 'w') do |f|
        f << 'application/epub+zip'
      end
    end
  end

  end
end
