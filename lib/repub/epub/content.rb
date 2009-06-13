require 'rubygems'
require 'builder'

module Repub
  module Epub
  
  class Content
    
    def initialize(uid)
      @metadata = Metadata.new('Untitled', 'en', uid)
      @css_counter = 0
      @img_counter = 0
      @html_counter = 0
      @manifest_items = []
      @spine_items = []
      @manifest_items << ContentItem.new('ncx', 'toc.ncx', 'application/x-dtbncx+xml')
    end
    
    class Metadata < Struct.new(
        :title,
        :language,
        :identifier,
        :subject,
        :description,
        :relation,
        :creator,
        :publisher,
        :date,
        :rights
      )
    end
    
    attr_reader :metadata
    
    def add_page_template(href = 'page-template.xpgt', id = 'pt')
      @manifest_items << ContentItem.new(id, href, 'application/vnd.adobe-page-template+xml')
    end
    
    def add_css(href, id = nil)
      @manifest_items << ContentItem.new(id || "css_#{@css_counter += 1}", href, 'text/css')
    end
    
    def add_img(href, id = nil)
      image_type = case(href.strip.downcase)
        when /.*\.(jpeg|jpg)$/
          'image/jpeg'
        when /.*\.png$/
          'image/png'
        when /.*\.gif$/
          'image/gif'
        when /.*\.svg$/
          'image/svg+xml'
        else
          raise 'Unsupported image type'
      end
      @manifest_items << ContentItem.new(id || "img_#{@img_counter += 1}", href, image_type)
    end
    
    def add_html(href, id = nil)
      manifest_item = ContentItem.new(id || "item_#{@html_counter += 1}", href, 'application/xhtml+xml')
      @manifest_items << manifest_item
      @spine_items << manifest_item
    end
    
    def to_xml
      out = ''
      builder = Builder::XmlMarkup.new(:target => out, :indent => 4)
      builder.instruct!
      builder.package :xmlns => "http://www.idpf.org/2007/opf",
          'unique-identifier' => "dcidid",
          'version' => "2.0" do
        metadata_to_xml(builder)
        manifest_to_xml(@manifest_items, builder)
        spine_to_xml(@spine_items, builder)
      end
      out
    end
    
    def save(path = 'content.opf')
      File.open(path, 'w') do |f|
        f << to_xml
      end
    end
    
    private
    
    def metadata_to_xml(builder)
      builder.metadata 'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
        'xmlns:dcterms' => "http://purl.org/dc/terms/",
        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        'xmlns:opf' => "http://www.idpf.org/2007/opf" do
          # Required elements
          builder.dc :title do
            builder << @metadata.title
          end
          builder.dc :language, 'xsi:type' => "dcterms:RFC3066" do
            builder << @metadata.language
          end
          builder.dc :identifier, :id => 'dcidid', 'opf:scheme' => 'URI' do
            builder << @metadata.identifier
          end
          # Optional elements
          builder.dc :subject do
            builder << @metadata.subject
          end if @metadata.subject
          builder.dc :description do
            builder << @metadata.description
          end if @metadata.description
          builder.dc :relation do
            builder << @metadata.relation
          end if @metadata.relation
          builder.dc :creator do
            builder << @metadata.creator
          end if @metadata.creator
          builder.dc :publisher do
            builder << @metadata.publisher
          end if @metadata.publisher
          builder.dc :date do
            builder << @metadata.date.to_s
          end if @metadata.date
          builder.dc :rights do
            builder << @metadata.rights
          end if @metadata.rights
      end
    end
    
    class ContentItem < Struct.new(
        :id,
        :href,
        :media_type
      )
    end
    
    def manifest_to_xml(manifest_items, builder)
      builder.manifest do
        manifest_items.each do |i|
          builder.item :id => i[:id], :href => i[:href], 'media-type' => i[:media_type]
        end
      end
    end
    
    def spine_to_xml(spine_items, builder)
      builder.spine do
        spine_items.each do |i|
          builder.itemref :idref => i[:id]
        end
      end
    end
  
  end
  
  end
end
