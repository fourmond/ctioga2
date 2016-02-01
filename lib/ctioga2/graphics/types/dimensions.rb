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
          if not @type.is_a? Symbol
            raise "Invalid value for the dimension type: '#{@type}'"
          end
          @value = value
          @orientation = orientation
        end

        def self.make_dimension(val, orient = :x, default = :figure)
          if val.is_a? Dimension
            return val
          else
            return Dimension.new(default, val, orient)
          end
        end

        # Gets the angle along the given direction
        def self.get_angle(t, dx, dy)
          dx = make_dimension(dx, :x).to_bp(t)
          dy = make_dimension(dy, :y).to_bp(t)
          return 180 * Math::atan2(dy, dx)/Math::PI
        end

        def -@
          return Dimension.new(@type, -@value, @orientation)
        end

        def *(fct)
          return Dimension.new(@type, @value*fct, @orientation)
        end

        # Returns a dimension corresponding to the distance.
        def self.get_distance(t, dx, dy)
          dx = make_dimension(dx, :x).to_bp(t)
          dy = make_dimension(dy, :y).to_bp(t)
          return Dimension.new(:bp, (dx**2 + dy**2)**0.5)
        end

        # Adjusts the given line by adding the dimensions on the left
        # and on the right (can be negative).
        #
        # Returns the new [x1, y1, x2, y2]
        def self.adjust_line(t, x1, y1, x2, y2, left, right)
          dx = x2 - x1
          dy = y2 - y1
          dst = get_distance(t, x2-x1, y2-y1).to_bp(t)
          lf = left.to_bp(t)/dst
          rf = right.to_bp(t)/dst

          x1 -= lf * dx
          y1 -= lf * dy
          x2 += rf * dx
          y2 += rf * dy
          return [x1, y1, x2, y2]
        end
          

        # Converts the Dimension to the *figure* coordinates of the
        # *current* figure in _t_.
        #
        # An extension of this function allows one to provide an ANGLE
        # instead of :x or :y for the orientation, in which case the
        # return value is a [dx, dy] array. In that case, the
        # dimension is first converted into a physical dimension in
        # the axis closest to the orientation and then one proceeds.
        def to_figure(t, orientation = nil)
          orientation ||= @orientation

          if ! orientation.is_a? Symbol
            angle = orientation.to_f * Math::PI/180.0
            dim = self
            if @type != :bp
              # Must first convert to physical dimension
              closest_orient = if Math::sin(angle)**2 > 0.5
                                 :y
                               else
                                 :x
                               end
              vl = dim.to_bp(t, closest_orient)
              dim = Dimension.new(:bp, vl)
            end
            dx = dim.to_figure(t, :x) * Math::cos(angle)
            dy = dim.to_figure(t, :y) * Math::sin(angle)
            return [dx, dy]
          end
          
          case @type
          when :bp
            return t.send("convert_output_to_figure_d#{orientation}", @value) * t.scaling_factor
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

        # Return the value of the dimension in units of text height
        def to_dy(t)
          fig = to_figure(t, :y)
          return fig/t.default_text_height_dy
        end

        # Converts the dimension into big points
        def to_bp(t, orientation = nil)
          orientation ||= @orientation
          return t.send("convert_figure_to_output_d#{orientation}", 
                        to_figure(t, orientation)) / t.scaling_factor
        end

        # Converts the Dimension to the *frame* coordinates of the
        # *current* frame in _t_.
        def to_frame(t, orientation = nil)
          orientation ||= @orientation
          return t.send("convert_figure_to_frame_d#{orientation}", 
                        to_figure(t, orientation))
        end

        # Express the Dimension in units of text height (dy)
        def to_text_height(t, orientation = nil)
          orientation ||= @orientation
          return self.to_figure(t, orientation)/
            t.send("default_text_height_d#{orientation}")
        end

        # Replace this Dimension by _dimension_ if the latter is
        # bigger. Conserves the current orientation.
        def replace_if_bigger(t, dimension)
          if self.to_figure(t) < dimension.to_figure(t, @orientation)
            @type = dimension.type
            @value = dimension.value
          end
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
        
        # A regular expression that matches all dimensions.
        DimensionRegexp = /^\s*([+-]?\s*[\d.eE+-]+)\s*([a-zA-Z]+)?\s*$/


        # Creates a Dimension object from a _text_ specification. The
        # text should be in the forms
        # 
        #  value unit
        #  
        # where unit is one of bp, pt, in, mm, cm, dy (the latter
        # being one unit of height) f|figure, F|Frame|frame,
        # p|page. It can be ommitted, in which case it defaults to the
        # _default_ parameter.
        def self.from_text(text, orientation, default = :figure)
          # Absolute or :dy dimension

          if text =~ /^\s*auto\s*$/i
            Dimension.new(:frame, 1.0, orientation)
          elsif text =~ DimensionRegexp
            value = Utils::txt_to_float($1)
            unit = $2
            if ! unit
              unit = default
            elsif DimensionConversion.key?(unit.downcase)
              value *= DimensionConversion[unit.downcase]
              unit = :bp
            else
              case unit
              when /^dy$/i
                unit = :dy
              when /^F|(?i:frame)$/
                unit = :frame
              when /^f|(?i:figure)$/
                unit = :figure
              when /^p|(?i:page)$/
                unit = :page
              else
                raise "Unkown dimension unit: #{unit}"
              end
            end
            return Dimension.new(unit, value, orientation)
          else
            raise "Unknown Dimension specification: '#{text}'"
          end
        end

        def set_from_text(str, default = :figure)
          dm  = Dimension.from_text(str, self.orientation, default)
          copy_from(dm)
        end

        # Copy from another dimension, omitting the orientation
        def copy_from(dm, orient = false)
          @type = dm.type
          @value = dm.value
          if orient
            @orientation = dm.orientation
          end
        end
          
        
      end

    end
    
  end

end

