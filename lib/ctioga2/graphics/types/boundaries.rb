# boundaries.rb: manipulation of Plot boundaries
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

      # A range of coordinates.
      class SimpleRange

        attr_accessor :first, :last

        # Create a new SimpleRange object that runs from _first_ to
        # _last_ (_last_ can be less than _first_). A _nil_,
        # _false_ or NaN in one of those means *unspecified*.
        #
        # Alternatively, _first_ can be an object that responds to
        # #first and #last.
        def initialize(first, last = nil)
          if first.respond_to?(:first)
            @first = first.first
            @last = first.last
          else
            @first = first
            @last = last
          end
        end

        # Minimum value
        def min
          @first < @last ? @first : @last
        end

        # Maximum value
        def max
          @first > @last ? @first : @last
        end

        # Algebraic distance
        def distance
          return @last - @first
        end

        # This function makes sures that the SimpleRange object is big
        # enough to encompass what it currently does and the _range_
        # SimpleRange object.
        #
        # \todo this does not work correctly in the case of reversed
        # boundaries. I don't think it can anyway.
        #
        # Actually, it even works with normal Range elements !
        def extend(range)
          # Left/right
          
          if (! @first.is_a? Float) or @first.nan? or
              (range.first && @first > range.first)
            @first = range.first
          end

          if (! @last.is_a? Float) or @last.nan? or
              (range.last && @last < range.last)
            @last = range.last
          end

          return self
        end


        # Override the Boundaries with the contents of _override_. All
        # elements which are not _nil_ or NaN from _override_
        # precisely override those in _self_.
        def override(override)
          for el in [ :first, :last]
            val = override.send(el)
            if val and (val == val) # Strip NaN on the property that NaN != NaN
              self.send("#{el}=", val)
            end
          end
        end

        # Apply a fixed margin on the Boundaries.
        def apply_margin!(margin)
          d = self.distance
          @first = @first - margin * d
          @last = @last + margin * d
        end

        # Returns a SimpleRange object that is large enough to exactly
        # contain all _values_
        def self.bounds(values)
          return SimpleRange.new(values.min, values.max)
        end

        # Takes an array of Boundaries and returns a Boundaries object
        # that precisely encompasses them all. Invalid floats are simply
        # ignored.
        def self.overall_range(ranges)
          retval = SimpleRange.new(nil, nil)
          for r in ranges
            retval.extend(b)
          end
          return retval
        end
      end


      # An object representing boundaries for a plot.
      #
      # \todo Should be converted to using two SimpleRange
      # objects. Will be more clear anyway.
      class Boundaries

        # Boundaries
        attr_accessor :left, :right, :top, :bottom

        # Creates a new Boundaries object with the given boundaries. A
        # _nil_, _false_ or NaN in one of those means *unspecified*.
        def initialize(left, right, top, bottom)
          @left = left
          @right = right
          @top = top
          @bottom = bottom
        end

        # Converts to an array suitable for use with Tioga.
        def to_a
          return [@left, @right, @top, @bottom]
        end

        # Minimum x value
        def xmin
          @left < @right ? @left : @right
        end

        # Maximum x value
        def xmax
          @left > @right ? @left : @right
        end

        # Minimum y value
        def ymin
          @bottom < @top ? @bottom : @top
        end

        # Maxiumum y value
        def ymax
          @bottom > @top ? @bottom : @top
        end

        # Returns a SimpleRange object corresponding to the horizontal
        # range
        def horizontal
          return SimpleRange.new(@left, @right)
        end

        # Returns a SimpleRange object corresponding to the vertical
        # range
        def vertical
          return SimpleRange.new(@bottom, @top)
        end


        # Converts to an [xmin, xmax, ymin, ymax] array
        def extrema
          return [xmin, xmax, ymin, ymax]
        end

        # The algebraic width of the boundaries
        def width
          return @right - @left
        end

        # The algebraic height of the boundaries
        def height
          return @top - @bottom
        end

        # This function makes sures that the Boundaries object is big
        # enough to encompass what it currently does and the _bounds_
        # Boundaries object.
        def extend(bounds)
          # Left/right
          if (! @left.is_a? Float) or @left.nan? or
              (@left > bounds.left)
            @left = bounds.left
          end
          if (! @right.is_a? Float) or @right.nan? or
              (@right < bounds.right)
            @right = bounds.right
          end

          # Top/bottom
          if (! @top.is_a? Float) or @top.nan? or
              (@top < bounds.top)
            @top = bounds.top
          end
          if (! @bottom.is_a? Float) or @bottom.nan? or
              (@bottom > bounds.bottom)
            @bottom = bounds.bottom
          end
          return self
        end


        # Override the Boundaries with the contents of _override_. All
        # elements which are not _nil_ or NaN from _override_
        # precisely override those in _self_.
        def override_boundaries(override)
          for el in [ :left, :right, :top, :bottom]
            val = override.send(el)
            if val and (val == val) # Strip NaN on the property that NaN != NaN
              self.send("#{el}=", val)
            end
          end
        end

        # Apply a fixed margin on the Boundaries.
        def apply_margin!(margin)
          w = self.width
          @left = @left - margin * w
          @right = @right + margin * w
          h = self.height
          @top = @top + margin * h
          @bottom = @bottom - margin * h
        end

        # Sets the values of the Boundaries for the _which_ axis from
        # the given _range_.
        def set_from_range(range, which)
          case which
          when :x
            @left, @right = range.first, range.last
          when :y
            @bottom, @top = range.first, range.last
          else
            raise "What is this #{which} axis ? "
          end
        end

        # Returns a boundary object that exactly contains all _x_values_
        # and _y_values_ (including error bars if applicable)
        def self.bounds(x_values, y_values)
          return Boundaries.new(x_values.min, x_values.max,
                                y_values.max, y_values.min)
        end

        # Takes an array of Boundaries and returns a Boundaries object
        # that precisely encompasses them all. Invalid floats are simply
        # ignored.
        def self.overall_bounds(bounds)
          retval = Boundaries.new(nil, nil, nil, nil)
          for b in bounds
            retval.extend(b)
          end
          return retval
        end

        # Creates a Boundaries object from two SimpleRange objects.
        def self.from_ranges(horiz, vert)
          return Boundaries.new(horiz.first, horiz.last,
                                vert.last, vert.first)
        end

      end
      
    end

  end

end
