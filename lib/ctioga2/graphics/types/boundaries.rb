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

  Version::register_svn_info('$Revision: 945 $', '$Date: 2009-04-12 01:03:50 +0200 (Sun, 12 Apr 2009) $')

  # This module contains all graphical elements of CTioga2
  module Graphics

    # A module holding different data types useful for interacting
    # with Tioga
    module Types

      # An object representing boundaries for a plot.
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

      end
      
    end

  end

end
