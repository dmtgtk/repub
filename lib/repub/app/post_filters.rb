require 'repub/app/filter'

module Repub
  class App
    class PostFilters
      
      class FileFilters
        include Filter
      
        # Do rx substitutions
        #
        filter :do_rxes do |s|
          options[:rx].each do |rx|
            rx.strip!
            delimiter = rx[0, 1]
            rx = rx.gsub(/\\#{delimiter}/, "\n")
            ra = rx.split(/#{delimiter}/).reject {|e| e.empty? }.each {|e| e.gsub!(/\n/, "#{delimiter}")}
            raise ParserException, "Invalid regular expression" if ra.empty? || ra[0].nil? || ra.size > 2
            pattern = ra[0]
            replacement = ra[1] || ''
            log.info "Replacing pattern /#{pattern.gsub(/#{delimiter}/, "\\#{delimiter}")}/ with \"#{replacement}\""
            s.gsub!(Regexp.new(pattern), replacement)
          end if options[:rx]
          s
        end

        # Remove xml preamble if any
        #
        filter :fix_xml_preamble do |s|
          preamble_rx = /^\s*<\?xml\s+[^>]+>\s*/mi
          if s =~ preamble_rx
            log.debug "-- Removing xml preamble"
            s.sub!(preamble_rx, '')
          end
          s
        end
      
        # Replace doctype
        #
        filter :fix_doctype do |s|
          doctype_rx = /^\s*<!DOCTYPE\s+[^>]+>\s*/mi
          if s =~ doctype_rx
            s.sub!(doctype_rx, '')
          end
          log.debug "-- Replacing doctype"
          s = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n" + s
          s
        end
      end
      
      class DocumentFilters
        include Filter

        # Set Content-Type charset to UTF-8
        #
        filter :fix_content_type do |doc|
          doc.xpath('//head/meta[@http-equiv="Content-Type"]').each do |el|
            el['content'] = 'text/html; charset=utf-8'
          end
          doc
        end

        # Process styles
        #
        filter :fix_styles do |doc|
          if options[:css] && !options[:css].empty?
            # Remove all stylesheet links
            doc.xpath('//head/link[@rel="stylesheet"]').remove
            if options[:css] == '-'
              # Also remove all inline styles
              doc.xpath('//head/style').remove
              log.info "Removing all stylesheet links and style elements"
            else
              # Add custom stylesheet link
              link = Nokogiri::XML::Node.new('link', doc)
              link['rel'] = 'stylesheet'
              link['type'] = 'text/css'
              link['href'] = File.basename(@options[:css])
              # Add as the last child so it has precedence over (possible) inline styles before
              doc.at('//head').add_child(link)
              log.info "Replacing CSS refs with \"#{link['href']}\""
            end
          end
          doc
        end

        # Insert elements after/before selector
        #
        filter :do_inserts do |doc|
          options[:after].each do |e|
            selector = e.keys.first
            fragment = e[selector]
            element = doc.xpath(selector).first
            if element
              log.info "Inserting fragment \"#{fragment.to_html}\" after \"#{selector}\""
              fragment.children.to_a.reverse.each {|node| element.add_next_sibling(node) }
            end
          end if options[:after]
          options[:before].each do |e|
            selector = e.keys.first
            fragment = e[selector]
            element = doc.xpath(selector).first
            if element
              log.info "Inserting fragment \"#{fragment}\" before \"#{selector}\""
              fragment.children.to_a.each {|node| element.add_previous_sibling(node) }
            end
          end if options[:before]
          doc
        end

        # Remove elements
        #
        filter :do_removes do |doc|
          options[:remove].each do |selector|
            log.info "Removing elements \"#{selector}\""
            doc.search(selector).remove
          end if options[:remove]
          doc
        end
        
        # TODO: XHTML requires a to have embedding element
        # filter :wrap_anchors do |doc|
        #   log.info "Wrapping anchors"
        #   doc.xpath('//body/a').each do |a|
        #     wrapper = Nokogiri::XML::Node.new('p', doc)
        #     a.add_next_sibling(wrapper)
        #     wrapper << a
        #   end
        #   doc
        # end
      end
      
    end
  end
end