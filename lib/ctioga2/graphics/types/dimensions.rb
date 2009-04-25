# dimensions.rb: various ways to represent a dimension in Tioga
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'ctioga2/utils'
require 'ctioga2/log'

module CTioga2

  Version::register_svn_info('$Revision: 943 $', '$Date: 2009-04-11 23:39:36 +0200 (Sat, 11 Apr 2009) $')

  module Graphics

    module Types

      # A Dimension is an object that represents a dimension in the
      # different ways understood by Tioga:
      # * an "absolute" dimension, ie, in real units (postscript points)
      # * a "text" dimension, in units of the height of the current
      #   text object
      # * a frame/page/figure dimension, in units of the *current*
      #   frame/page/figure coordinates
      class Dimension

        include Tioga::Utils

        # What is the underlying representation of the dimension ?
        # * :bp in postscript points
        # * :dy in text height units
        # * :frame in frame coordinates
        # * :page in page coordinates
        # * :figure in figure coordinates
        attr_accessor :type

        # The orientation of the dimension: vertical (:y) or
        # horizontal (:x) ?
        attr_accessor :orientation

        # The actual dimension. The interpretation depends on the
        # value of #type.
        attr_accessor :value

        # Creates a Dimension object of the given _type_, the given
        # _value_ oriented along the given _orientation_
        def initialize(type, value, orientation = :x)
          @type = type
          @value = value
          @orientation = orientation
        end

        # Converts the Dimension to the *figure* coordinates of the
        # *current* figure in _t_.
        def to_figure(t, orientation = nil)
          orientation ||= @orientation
          case @type
          when :bp
            return t.send("convert_output_to_figure_d#{orientation}", @value) * 10
          when :dy
            return t.send("default_text_height_d#{orientation}") * @value
          when :frame
            return t.send("convert_frame_to_figure_d#{orientation}", @value)
          when :page
            return t.send("convert_page_to_figure_d#{orientation}", @value)
          when :figure
            return @value
          else
            raise "Invalid type for Dimension: #{@type}"
          end
        end

        # Converts the Dimension to the *frame* coordinates of the
        # *current* frame in _t_.
        def to_frame(t, orientation = nil)
          orientation ||= @orientation
          return t.send("convert_figure_to_frame_d#{orientation}", 
                        to_figure(t, orientation))
        end

        # Dimension conversion constants taken straight from the
        # TeXbook
        DimensionConversion = {
          "pt" => (72.0/72.27),
          "bp" => 1.0,
          "in" => 72.0,
          "cm" => (72.0/2.54),
          "mm" => (72.0/25.4),
        }


        # Creates a Dimension object from a _text_ specification. The
        # text should be in the forms:
        # 
        # * value unit, where unit is one of bp, pt, in, mm, cm and dy
        #   (the latter being one unit of height)
        # * spec: value, where spec is one of p(page), f(figure) or
        #   F (frame). spec: can be omitted, it will default to
        #   _default_
        def self.from_text(text, orientation, default = :figure)
          # Absolute or :dy dimension
          if text =~ /^\s*([+-]?[\d.]+)\s*([a-z]+)\s*$/
            value = Float($1)
            unit = $2
            if unit == 'dy'
              return Dimension.new(:dy, value, orientation)
            else
              if DimensionConversion.key? unit
                return Dimension.new(:bp, value * DimensionConversion[unit], 
                                     orientation)
              else
                raise "Unkown dimension unit: #{unit}"
              end
            end
          elsif text =~ /^\s*(?:([Ffp]):)?\s*(.*)\s*$/
            spec = $1
            value = Float($2)
            if spec
              case spec
              when 'F'
                spec = :frame
              when 'f'
                spec = :figure
              when 'p'
                spec = :page
              end
            else
              spec = default
            end
            return Dimension.new(spec, value, orientation)
          else
            raise "Unkown Dimension specification: '#{text}'"
          end
        end
      end

    end
    
  end

end

