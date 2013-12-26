# boxes.rb: various ways to represent a box in Tioga
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

  # This module contains all graphical elements of CTioga2
  module Graphics

    # A module holding different data types useful for interacting
    # with Tioga
    module Types

      # The base class for different kind of boxes
      class Box

        def initialize
          raise "Use a derived class !"
        end

        # This function returns the frame coordinates of the box, in
        # the form:
        #  [ xl, yt, xr, yb ]
        # This function *must* be reimplemented in children.
        def to_frame_coordinates(t)
          raise "Reimplement this in children !"
        end

        # Converts this object into an array suitable for use with
        # FigureMaker#set_sub_frame.
        def to_frame_margins(t)
          xl, yt, xr, yb = self.to_frame_coordinates(t)
          return [xl, 1 - xr, 1 - yt, yb]
        end
        
      end

      # A box defined by its margins
      class MarginsBox < Box

        # Margin specifications. These are Dimension objects.
        attr_accessor :left, :right, :top, :bottom

        # Creates a new MarginsBox object with the specified margins,
        # as String (passed on to Dimension::to_text), float (defaults
        # to frame coordinates) or directly as Dimension objects.
        #
        # The Dimension's orientation is automatically tweaked.
        def initialize(left, right, top, bottom)
          # First, convert any float into Dimension:
          a = [left, right, top, bottom]
          a.each_index do |i|
            if ! a[i].is_a? Dimension
              a[i] = Dimension::from_text(a[i].to_s, :x, :frame)
            end
          end
          left, right, top, bottom = a

          # Then assign to the appropriate stuff:
          @left = left
          @left.orientation = :x
          @right = right
          @right.orientation = :x
          @top = top
          @top.orientation = :y
          @bottom = bottom
          @bottom.orientation = :y
        end

        def to_frame_coordinates(t)
          return [@left.to_frame(t), 1 - @top.to_frame(t),
                  1 - @right.to_frame(t), @bottom.to_frame(t)]
        end

        # Returns the dimensions composing the MarginsBox, in the
        # order _left_, _right_, _top_, _bottom_, suitable for feeding
        # to MarginsBox.new.
        def margins
          return [@left, @right, @top, @bottom]
        end

      end

      # A box defined by an AlignedPoint and two dimensions
      class PointBasedBox < Box

        # The aligned point of the box:
        attr_accessor :point

        # The width
        attr_accessor :width
        
        # The height
        attr_accessor :height

        # Creates a new PointBasedBox at the given _point_, with the
        # given _width_ and _height_.
        def initialize(point, width, height)
          @point = point
          @width = width
          @height = height
        end

        # A well formed point-based box must match the following
        # regular expression.
        PointBasedBoxRE = /^\s*(.*):([^,]+)(?:,\s*(.*))?$/

        # Returns a new PointBasedBox object based on the text
        # specification, which reads:
        #
        #   aligned_point:w(,h)
        #
        # The default holds for point and dimensions
        def self.from_text(text, default = :frame)
          if text =~ PointBasedBoxRE
            po,w,h = $1,$2,$3
            point = AlignedPoint.from_text(po, default)
            width = Dimension.from_text(w, :x, default)
            if h
              height = Dimension.from_text(h, :y, default)
            else
              height = width.dup
            end
            return PointBasedBox.new(point, width, height)
          else
            raise "#{text} is not a point-based box."
          end
        end

        # Returns the frame coordinates of the box.
        def to_frame_coordinates(t)
          dx = @width.to_figure(t, :x)
          dy = @height.to_figure(t, :y)
          a = @point.to_frame_coordinates(t, dx, dy)
          return @point.to_frame_coordinates(t, dx, dy)
        end
        
      end

    end
  end
end

