require 'rubygems'

module Repub
  module Epub

    # Mixin for stuff that can be added to the ePub package
    #
    module Containable
      attr_accessor :file_path
      attr_accessor :media_type
      
      def document?
        ['application/xhtml+xml', 'application/x-dtbook+xml'].include? @media_type
      end
    end
    
    # Wrapper class for ePub items that do not have specialized classes
    # e.g. HTML files, CSSs etc.
    #
    class Item
      include Containable
      
      def initialize(file_path, media_type = nil)
        @file_path = file_path.strip
        @media_type = media_type || case @file_path.downcase
          when /.*\.html?$/
            'application/xhtml+xml'
          when /.*\.css$/
            'text/css'
          when /.*\.(jpeg|jpg)$/
            'image/jpeg'
          when /.*\.png$/
            'image/png'
          when /.*\.gif$/
            'image/gif'
          when /.*\.svg$/
            'image/svg+xml'
          when /.*\.ncx$/
            'application/x-dtbncx+xml'
          when /.*\.opf$/
            'application/oebps-package+xml'
          else
            raise 'Unknown media type'
        end
      end
    end

  end
end