require 'rubygems'
require 'builder'

module Repub
  module Epub
  
  # Open Packaging Format (OPF) 2.0 wrapper
  # (see http://www.idpf.org/2007/opf/OPF_2.0_final_spec.html)
  #
  class OPF
    include Containable
    
    def initialize(uid, file_path = 'package.opf')
      @file_path = file_path
      @media_type = 'application/oebps-package+xml'
      @metadata = Metadata.new('Untitled', 'en', uid, Date.today.to_s)
      @items = []
    end
    
    class Metadata < Struct.new(
        :title,
        :language,
        :identifier,
        :date,
        :subject,
        :description,
        :relation,
        :creator,
        :publisher,
        :rights
      )
      
      def to_xml(builder)
        builder.metadata 'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
          'xmlns:dcterms' => "http://purl.org/dc/terms/",
          'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
          'xmlns:opf' => "http://www.idpf.org/2007/opf" do
            # Required elements
            builder.dc :title do
              builder << self.title
            end
            builder.dc :language, 'xsi:type' => "dcterms:RFC3066" do
              builder << self.language
            end
            builder.dc :identifier, :id => 'dcidid', 'opf:scheme' => 'URI' do
              builder << self.identifier
            end
            # Optional elements
            builder.dc :subject do
              builder << self.subject
            end if self.subject
            builder.dc :description do
              builder << self.description
            end if self.description
            builder.dc :relation do
              builder << self.relation
            end if self.relation
            builder.dc :creator do                  # TODO: roles
              builder << self.creator
            end if self.creator
            builder.dc :publisher do
              builder << self.publisher
            end if self.publisher
            builder.dc :date do
              builder << self.date.to_s
            end if self.date
            builder.dc :rights do
              builder << self.rights
            end if self.rights
        end
      end
    end
    
    attr_reader :metadata
    attr_reader :items
    
    def <<(item)
      if item.kind_of? Containable
        @items << item
      elsif item.is_a? String
        @items << Item.new(item)
      else
        raise "Unsupported item class: #{item.class}"
      end
    end

    def to_xml
      out = ''
      builder = Builder::XmlMarkup.new(:target => out)
      builder.instruct!
      builder.package :xmlns => "http://www.idpf.org/2007/opf",
          'unique-identifier' => "dcidid",
          'version' => "2.0" do
        @metadata.to_xml(builder)
        manifest_to_xml(builder)
        spine_to_xml(builder)
      end
      out
    end
    
    def save
      File.open(@file_path, 'w') do |f|
        f << to_xml
      end
    end
    
    private

    def manifest_to_xml(builder)
      builder.manifest do
        @items.each_with_index do |item, index|
          builder.item :id => index.to_s, :href => item.file_path, 'media-type' => item.media_type
        end
      end
    end
    
    def spine_to_xml(builder)
      builder.spine do
        @items.each_with_index do |item, index|
          builder.itemref :idref => index.to_s if item.document?
        end
      end
    end
  end
  
  end
end
