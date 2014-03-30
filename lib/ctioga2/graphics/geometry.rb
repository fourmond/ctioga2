# geometry.rb: various geometry-related utility classes
# copyright (c) 2014 by Vincent Fourmond
  
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


    # A geometry line, ie something that has a starting point and a
    # direction. It is infinite
    class Line

      # Checks if within the bounds of the line (but not necessarily
      # ON the line)
      def within_bounds?(x, y)
        return true
      end

      attr_accessor :x, :y, :dx, :dy

      def initialize(x, y, dx, dy)
        @x = x.to_f
        @y = y.to_f
        @dx = dx.to_f
        @dy = dy.to_f
      end

      # Returns the X and Y positions of the intersection with the
      # given Line, or false should there be none.
      def intersection(line)
        fact = @dx * line.dy - line.dx * @dy
        rhs =  @dy * (line.x - @x) - @dx * (line.y - @y)
        if fact != 0            # There is a unique intersection
          beta = rhs/fact
          nx = line.x + beta * line.dx
          ny = line.y + beta * line.dy
        # elsif rhs == 0
        #   # Infinite, we return 
        #   return 
        else
          return false
        end
        return [nx, ny] if (within_bounds?(nx, ny) and 
                            line.within_bounds?(nx, ny))
        return false
      end
    end

    # Same as line, but with a beginning and an end
    class Segment < Line

      attr_accessor :x2, :y2

      def initialize(x1, y1, x2, y2)
        @x2 = x2
        @y2 = y2
        super(x1, y1, x2 - x1, y2 - y1)
      end


      def within_bounds?(x, y)
        return (
                (
                 (x - @x) * (x - @x2) <= 0 or
                 (x - @x).abs < 1e-15 or
                 (x - @x2).abs < 1e-15
                 ) and 
                ((y - @y) * (y - @y2) <= 0 or
                 (y - @y).abs < 1e-15 or
                 (y - @y2).abs < 1e-15
                 )
                )
      end

      def to_line()
        return Line.new(@x, @y, @dx, @dy)
      end
    end
  end

end

