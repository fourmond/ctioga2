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

        # Checks if the range is valid, that is both elements are
        # finite numbers
        def valid?
          return (Utils::finite_number?(@first) and
                  Utils::finite_number?(@last))
        end

        def nan?
          return (Utils::nan_number?(@first) or
                  Utils::nan_number?(@last))
        end

        def infinite?
          return (Utils::infinite_number?(@first) or
                  Utils::infinite_number?(@last))
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

        # Two SimpleRange objects
        attr_accessor :horiz, :vert

        # Creates a new Boundaries object with the given boundaries. A
        # _nil_, _false_ or NaN in one of those means *unspecified*.
        def initialize(horiz, vert)
          @horiz = horiz || SimpleRange.new(nil, nil)
          @vert = vert || SimpleRange.new(nil, nil)
        end

        def initialize_copy(orig)
          @horiz = orig.horiz.dup
          @vert = orig.vert.dup
        end

        def left
          return @horiz.first
        end

        def left=(v)
          @horiz.first = v
        end

        def right
          return @horiz.last
        end

        def right=(v)
          @horiz.last = v
        end

        def top
          return @vert.last
        end

        def top=(v)
          @vert.last = v
        end

        def bottom
          return @vert.first
        end

        def bottom=(v)
          @vert.first=(v)
        end

        # Converts to an array suitable for use with Tioga.
        def to_a
          return [left, right, top, bottom]
        end

        # Minimum x value
        def xmin
          @horiz.min
        end

        # Maximum x value
        def xmax
          @horiz.max
        end

        # Minimum y value
        def ymin
          @vert.min
        end

        # Maxiumum y value
        def ymax
          @vert.max
        end

        # Returns a SimpleRange object corresponding to the horizontal
        # range
        def horizontal
          return @horiz
        end

        # Returns a SimpleRange object corresponding to the vertical
        # range
        def vertical
          return @vert
        end


        # Converts to an [xmin, xmax, ymin, ymax] array
        def extrema
          return [xmin, xmax, ymin, ymax]
        end

        # The algebraic width of the boundaries
        def width
          return @horiz.distance
        end

        # The algebraic height of the boundaries
        def height
          return @vert.distance
        end

        # This function makes sures that the Boundaries object is big
        # enough to encompass what it currently does and the _bounds_
        # Boundaries object.
        def extend(bounds)
          @horiz.extend(bounds.horiz)
          @vert.extend(bounds.vert)
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
          @horiz.apply_margin!(margin)
          @vert.apply_margin!(margin)
        end

        # Sets the values of the Boundaries for the _which_ axis from
        # the given _range_.
        def set_from_range(range, which)
          case which
          when :x
            @horiz = range
          when :y
            @vert = range
          else
            raise "What is this #{which} axis ? "
          end
        end

        # Returns a boundary object that exactly contains all _x_values_
        # and _y_values_ (including error bars if applicable)
        def self.bounds(x_values, y_values)
          return Boundaries.new(SimpleRange.bounds(x_values),
                                SimpleRange.bounds(y_values))
        end

        # Takes an array of Boundaries and returns a Boundaries object
        # that precisely encompasses them all. Invalid floats are simply
        # ignored.
        def self.overall_bounds(bounds)
          retval = Boundaries.new(nil, nil)
          for b in bounds
            retval.extend(b)
          end
          return retval
        end

        # Creates a Boundaries object from two SimpleRange objects.
        def self.from_ranges(horiz, vert)
          return Boundaries.new(horiz.dup, vert.dup)
        end

      end
      
    end

  end

end
