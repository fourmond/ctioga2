# indexed-dtable.rb: A Dtable object with non-uniform XY values
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

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')


  module Data

    # An indexed Dtable.
    #
    # This object represents an indexed Dtable, that is a Dtable with
    # given values of X and Y (not necessarily uniform). Its main use
    # is to get back a uniform (non-indexed) Dtable, for use with
    # create_image
    #
    # An important information is that places where there was no data
    # is implicitly represented as NaN
    class IndexedDTable

      # The underlying Dtable
      attr_accessor :table

      # X values
      attr_accessor :x_values

      # Y values
      attr_accessor :y_values

      def initialize(x, y, t)
        @table = t
        @x_values = x
        @y_values = y
      end

      # Returns the XY boundaries of the object
      def xy_boundaries
        return Graphics::Types::Boundaries.bounds(@x_values, @y_values)
      end

      # Returns the value by which one should shift the X and Y
      # positions of the borders of the images in order to get the
      # points centered on their pixel (for a *uniform* grid !).
      #
      # While this correction looks better on non-uniform grids, it
      # does not guarantee that it places all the points int the
      # middle of their pixel, but that is still true for the ones at
      # the border.
      def xy_correction
        return [(@x_values.last - @x_values.first)/ (2 * @x_values.size),
                (@y_values.last - @y_values.first)/ (2 * @y_values.size)]
      end

      # Returns the coordinates of the lower-left XY values
      def ll
        return [@x_values.first, @y_values.first]
      end

      # Returns the coordinates of the lower-left XY values
      def lr
        return [@x_values.last, @y_values.first]
      end

      # Returns the coordinates of the upper-right XY values
      def ur
        return [@x_values.last, @y_values.last]
      end

      # Returns the coordinates of the upper-right XY values
      def ul
        return [@x_values.first, @y_values.last]
      end

      # Returns a hash ul,ll,lr with the corresponding values of the
      # the points, with the correction applied if correction is true
      def corner_positions(correction = true)
        dict = {
          'll' => ll,
          'lr' => lr,
          'ul' => ul
        }
        if correction
          dx, dy = *xy_correction
          # This isn't really beautiful, but it just works.
          dict['ll'][0] -= dx
          dict['lr'][0] += dx
          dict['ul'][0] -= dx

          dict['ll'][1] -= dy
          dict['lr'][1] -= dy
          dict['ul'][1] += dy
        end
        return dict
      end

      def width
        return @x_values.size
      end

      def height
        return @y_values.size
      end

    end

  end

end

