require 'repub/app/filter'

module Repub
  class App
    class PreFilters
      include Filter
      
      # Detect and convert source encoding
      # Standard requires it to be UTF-8
      #
      filter :fix_encoding do |s|
        encoding = options[:encoding]
        unless encoding
          log.info "Detecting encoding"
          encoding = UniversalDetector.chardet(s)['encoding']
        end
        if encoding.downcase != 'utf-8'
          log.info "Source encoding appears to be #{encoding}, converting to UTF-8"
          s = Iconv.conv('utf-8', encoding, s)
        end
        s
      end

      # Convert line endings to LF
      #
      filter :fix_line_endings do |s|
        s.gsub(/\r\n/, "\n")
      end

      # Fix all elements with broken id attribute
      # In XHTML id must match [A-Za-z][A-Za-z0-9:_.-]*
      # TODO: currently only testing for non-alpha first char...
      #
      filter :fix_ids do |s|
        match = s.scan(/\s+((?:id|name)\s*?=\s*?['"])(\d+[^'"]*)['"]/im)
        unless match.empty?
          log.debug "-- Fixing broken element IDs"
          match.each do |m|
            # fix id so it starts with alpha char
            s.gsub!(m.join(''), m.join('x'))
            # update fragment references
            s.gsub!(/##{m[1]}(['"])/, "#x#{m[1]}\\1")
          end
        end
        s
      end

    end
  end
end