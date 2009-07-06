require 'rubygems'
require 'builder'

module Repub
  module Epub
  
  class NCX
    include Containable
    
    def initialize(uid, file_path = 'toc.ncx')
      @file_path = file_path
      @media_type = 'application/x-dtbncx+xml'
      @head = Head.new(uid)
      @doc_title = DocTitle.new('Untitled')
      @nav_map = NavMap.new
    end

    def title
      @doc_title.text
    end
    
    def title=(text)
      @doc_title = DocTitle.new(text)
    end

    attr_reader :nav_map
    
    def to_xml
      out = ''
      builder = Builder::XmlMarkup.new(:target => out)
      builder.instruct!
      builder.declare! :DOCTYPE, :ncx, :PUBLIC, "-//NISO//DTD ncx 2005-1//EN", "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd"
      builder.ncx :xmlns => "http://www.daisy.org/z3986/2005/ncx/", :version => "2005-1" do
        @nav_map.calc_depth_and_play_order
        @head.depth = @nav_map.depth
        @head.to_xml(builder)
        @doc_title.to_xml(builder)
        @nav_map.to_xml(builder)
      end
      out
    end
    
    def save
      File.open(@file_path, 'w') do |f|
        f << to_xml
      end
    end
    
    class Head < Struct.new(
        :uid
      )
      
      attr_accessor :depth
      
      def to_xml(builder)
        builder.head do 
          builder.meta :name => "dtb:uid", :content => self.uid
          builder.meta :name => "dtb:depth", :content => @depth
          builder.meta :name => "dtb:totalPageCount", :content => 0
          builder.meta :name => "dtb:maxPageNumber", :content => 0
        end
      end
    end
    
    class DocTitle < Struct.new(
        :text
      )
      
      def to_xml(builder)
        builder.docTitle do 
          builder.text self.text
        end
      end
    end
    
    class NavPoint < Struct.new(
        :title,
        :src
      )
      
      def initialize(title, src)
        super
        #@@last_play_order = 0
        @play_order = 0
        @points = []
      end
      
      attr_accessor :play_order
      attr_reader :points
      
      def to_xml(builder)
        builder.navPoint :id => @play_order.to_s, :playOrder => @play_order do
          builder.navLabel do
            builder.text self.title
          end
          builder.content :src => self.src
          @points.each { |point| point.to_xml(builder) }
        end
      end
    end

    class NavMap < NavPoint
      def initialize
        super(nil, nil)
        @depth = 1
      end
      
      attr_reader :depth
      
      def calc_depth_and_play_order
        play_order = 0
        l = lambda do |points, depth|
          @depth = depth if depth > @depth
          points.each do |point|
            point.play_order = play_order += 1
            l.call(point.points, depth + 1) unless point.points.empty?
          end
        end
        @depth = 1
        l.call(@points, @depth)
      end
      
      def to_xml(builder)
        builder.navMap do
          @points.each { |point| point.to_xml(builder) }
        end
      end
    end
  end

  end
end
