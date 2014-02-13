# point.rb: various ways to represent a position in Tioga
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details (in the COPYING file).

require 'ctioga2/utils'
require 'ctioga2/log'

module CTioga2

  module Graphics

    module Types

      # This class performs the same function as Dimension, except
      # that it represents a *coordinate*. As such, its #value only
      # makes sense as a page, frame or figure coordinate
      class BaseCoordinate < Dimension
        
        # Creates a BaseCoordinate object of the given _type_, the
        # given _value_ and oriented along the given _orientation_
        def initialize(type, value, orientation)
          super
        end

        # Converts the Dimension to the *figure* coordinates of the
        # *current* figure in _t_.
        def to_figure(t, orientation = nil)
          orientation ||= @orientation
          case @type
          when :frame
            return t.send("convert_frame_to_figure_#{orientation}", @value)
          when :page
            return t.send("convert_page_to_figure_#{orientation}", @value)
          when :figure
            return @value
          else
            raise "Invalid type for BaseCoordinate: #{@type}"
          end
        end

        # Converts the Dimension to the *frame* coordinates of the
        # *current* frame in _t_.
        def to_frame(t, orientation = nil)
          orientation ||= @orientation
          return t.send("convert_figure_to_frame_#{orientation}",  
                        to_figure(t, orientation))
        end

        # Creates a BaseCoordinate object from a text
        # specification. Takes the same argument as
        # Dimension.from_text, except that purely dimension #type
        # won't be accepted.
        def self.from_text(text, orientation, default = :figure)
          dim = Dimension.from_text(text, orientation, default)
          if dim.type == :bp or dim.type == :dy
            raise "Does not accept dimensions only for coordinates"
          end
          return BaseCoordinate.new(dim.type, dim.value, dim.orientation)
        end
        
      end


      # Represents a given Point for Tioga. Its coordinates are
      # BaseCoordinate objects.
      class Point

        # The X coordinate, a BaseCoordinate object
        attr_accessor :x
        
        # The Y coordinate, a BaseCoordinate object
        attr_accessor :y
        
        # Creates a Point with the given coordinates (of type _type_,
        # see BaseCoordinate for more information).
        def initialize(x = nil, y = nil, type = :figure)
          if x && y
            @x = BaseCoordinate.new(type, x, :x)
            @y = BaseCoordinate.new(type, y, :y)
          end
        end

        # Converts the point to figure coordinates.
        def to_figure_xy(t)
          return [@x.to_figure(t), @y.to_figure(t)]
        end

        # Converts the points to frame coordinates.
        def to_frame_xy(t)
          return [@x.to_frame(t), @y.to_frame(t)]
        end

        # Creates a Point object from a text specification. Splits up
        # the text at a comma and 
        def self.from_text(text, default = :figure)
          vals = text.split(/\s*,\s*/)
          if vals.size != 2
            raise "Should really have two values: #{text}"
          end
          coord = Point.new
          coord.x = BaseCoordinate.from_text(vals[0], :x, default)
          coord.y = BaseCoordinate.from_text(vals[1], :y, default)
          return coord
        end
      end

      class Rect 
        attr_accessor :tl
        attr_accessor :br

        def initialize(tl, br)
          @tl = tl
          @br = br
        end

        # Returns the [height, width] of the rectangle in postscript points
        def dimensions(t)
          xl, yt = @tl.to_figure_xy(t)
          xr, yb = @br.to_figure_xy(t)

          return [t.convert_figure_to_output_dx(xr - xl) * 10,
                  t.convert_figure_to_output_dy(yb - yt) * 10]
        end

        # Returns an array of [ul, ll, lr] coordinates. If an aspect
        # ratio is specified, the coordinates will be expanded or
        # contracted to fit the aspect ratio (keeping the center
        # identical).
        def make_corners(t, swap = false, ratio_pol = :ignore, 
                         ratio = nil)
          
          ul = @tl.to_figure_xy(t)
          lr = @br.to_figure_xy(t)

          width, height = *dimensions(t)

          # First, swap the coords
          if swap
            if width < 0
              ul[0], lr[0] = lr[0], ul[0]
            end
            if height > 0
              ul[1], lr[1] = lr[1], ul[1]
            end
          end

          # Now, we take the aspect ratio into account
          if ratio && ratio_pol != :ignore

            xc = 0.5 * (ul[0] + lr[0])
            yc = 0.5 * (ul[1] + lr[1])
            dx = lr[0] - ul[0]
            dy = lr[1] - ul[1]

            fact = ((width/height) / ratio).abs

            what = nil

            if ratio_pol == :expand
              if fact > 1       # must increase height
                what = :y
              else
                fact = 1/fact
                what = :x
              end
            elsif ratio_pol == :contract
              if fact > 1       # must decrease width
                what = :x
                fact = 1/fact
              else
                what = :y
              end
            else
              raise "Unkown aspect ratio policy: #{ratio_pol}"
            end

            if what == :y
              lr[1] = yc + fact * 0.5 * dy
              ul[1] = yc - fact * 0.5 * dy
            else
              lr[0] = xc + fact * 0.5 * dx
              ul[0] = xc - fact * 0.5 * dx
            end
          end

          ll = [ul[0], lr[1]]

          return [ul, ll, lr]
        end

      end

      # A Point, but with alignment facilities.
      class AlignedPoint < Point
        # Vertical alignement (:top, :center, :bottom)
        attr_accessor :valign

        # Horizontal alignment (:left, :center, :right)
        attr_accessor :halign

        # Creates a AlignedPoint
        def initialize(x = nil, y = nil, type = :figure, 
                       halign = :center, valign = :center)
          super(x,y,type)
          @halign = halign
          @valign = valign
        end

        # Returns frame coordinates corresponding to the point, the
        # alignment and the given size in figure coordinates
        def to_frame_coordinates(t, width, height)
          dx = t.convert_figure_to_frame_dx(width).abs
          dy = t.convert_figure_to_frame_dy(height).abs
          x,y = self.to_frame_xy(t)

          case @valign
          when :top
            yt = y
            yb = y - dy
          when :bottom
            yt = y + dy
            yb = y
          when :center
            yt = y + dy/2
            yb = y - dy/2
          else 
            raise "Unknown vertical alignment: #{@valign}"
          end

          case @halign
          when :right
            xl = x - dx
            xr = x
          when :left
            xl = x
            xr = x + dx
          when :center
            xl = x - dx/2
            xr = x + dx/2
          else 
            raise "Unknown horizontal alignment: #{@halign}"
          end
          return [xl, yt, xr, yb]
        end

        # Returns a frame_margin corresponding to the point, the
        # alignment and the given size in figure coordinates.
        #
        # See #to_frame_coordinates
        def to_frame_margins(t, width, height)
          xl, yt, xr, yb = to_frame_coordinates(t, width, height)
          return [xl,1 - xr, 1 - yt, yb]
        end

        AlignmentSpecification = {
          'r' => :right,
          'c' => :center,
          'l' => :left,
          't' => :top,
          'b' => :bottom
        }
          

        # Creates an AlignedPoint object from a text
        # specification. Splits up the text at a comma and
        def self.from_text(text, default = :figure)
          if not text =~ /^\s*([btlrc]{2})(?::([^,]+),\s*(.*))?\s*$/
            raise "Invalid format for aligned point: #{text}"
          end

          specs = $1
          specs = specs.chars.map {|x| 
            AlignmentSpecification.fetch(x.downcase)
          }
          coord = AlignedPoint.new
          if specs[0] == :center
            specs.reverse!
          end
          case specs[0]
          when :center
            coord.halign = :center
            coord.valign = :center
          when :left, :right
            coord.halign = specs[0]
            coord.valign = specs[1]
          when :top, :bottom
            coord.valign = specs[0]
            coord.halign = specs[1]
          end

          if $2
            x_spec,y_spec = $2,$3
            coord.x = BaseCoordinate.from_text(x_spec, :x, default)
            coord.y = BaseCoordinate.from_text(y_spec, :y, default)
          else
            case coord.halign
            when :center
              coord.x = BaseCoordinate.new(:frame, 0.5, :x)
            when :left
              coord.x = BaseCoordinate.new(:frame, 0.05, :x)
            when :right
              coord.x = BaseCoordinate.new(:frame, 0.95, :x)
            end

            case coord.valign
            when :center
              coord.y = BaseCoordinate.new(:frame, 0.5, :y)
            when :bottom
              coord.y = BaseCoordinate.new(:frame, 0.05, :y)
            when :top
              coord.y = BaseCoordinate.new(:frame, 0.95, :y)
            end
          end
          return coord
        end
      end
    end
    
  end

end

