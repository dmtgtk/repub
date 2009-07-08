require 'repub/app/filter'

module Repub
  class App
    class PreFilter
      include Filter
      
      # Detect and convert source encoding
      # Standard requires it to be UTF-8
      #
      filter :fix_encoding do |content|
        encoding = options[:encoding]
        unless encoding
          log.info "Detecting encoding"
          encoding = UniversalDetector.chardet(content)['encoding']
        end
        if encoding.downcase != 'utf-8'
          log.info "Source encoding appears to be #{encoding}, converting to UTF-8"
          content = Iconv.conv('utf-8', encoding, content)
        end
        content
      end

      # Find and fix all elements with id or name attributes beginning with digit
      # ADE wont follow links referencing such ids
      #
      filter :fix_ids do |content|
        match = content.scan(/\s+(?:id|name)\s*?=\s*?['"](\d+[^'"]*)['"]/im)
        unless match.empty?
          log.debug "-- Fixing broken element IDs"
          match.each do |m|
            content.gsub!(m[0], "x#{m[0]}")
          end
        end
        content
      end

    end
  end
end