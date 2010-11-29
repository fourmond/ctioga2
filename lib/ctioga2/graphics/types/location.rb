# location.rb: handling the concept of "location" (for an axis especially)
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

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Types


      # Location of an object (especially axes) in a plot, in terms of
      # the side of the plot or the X and Y axis.
      class PlotLocation

        # Conversion between the #base_location attribute and the real
        # constant used for Tioga
        LocationToTiogaLocation = {
          :left => Tioga::FigureConstants::LEFT,
          :right => Tioga::FigureConstants::RIGHT,
          :bottom => Tioga::FigureConstants::BOTTOM,
          :top => Tioga::FigureConstants::TOP,
          :at_x_origin => Tioga::FigureConstants::AT_X_ORIGIN,
          :at_y_origin => Tioga::FigureConstants::AT_Y_ORIGIN
        }

        # Horizontal or vertical
        LocationVertical = {
          :left => true,
          :right => true,
          :bottom => false,
          :top => false,
          :at_x_origin => true,
          :at_y_origin => false
        }


        # The position of the object, one of :left, :right, :top,
        # :bottom, :at_y_origin or :at_x_origin.
        #
        # @todo This will have to be extended to allow possibly
        # arbitrary frame/figure placement.
        attr_accessor :base_location

        # The shift away from the position given by #base_location.
        #
        # This will be a Dimension object.
        #
        # @todo This is not currently implemented
        attr_accessor :shift
        

        # Creates a new PlotLocation object, either copying the one
        # given as argument or from scratch specifying at least the
        # base location.
        def initialize(location, shift = nil)
          if location.respond_to? :shift
            @base_location = location.base_location
            @shift = shift || location.shift
          else
            @base_location = location
            @shift = shift
          end
        end

        # Returns the tioga location (ie that suitable for sending to
        # show_axis for instance)
        def tioga_location
          return LocationToTiogaLocation[@base_location]
        end

        # Whether the given location is vertical or horizontal
        def vertical?
          return LocationVertical[@base_location]
        end

        # Extra extension that should be reserved for a label on the
        # given side based on simple heuristics. Value is returned in
        # text height units.
        def label_extra_space(t)
          case @base_location
          when :bottom, :right
            extra = 0.5       # To account for baseline ?
          when :top, :left
            extra = 1
          else                # We take the safe side !
            extra = 1
          end
          if @shift
            ## @todo Here add the shift
          end
          return extra
        end

        # Returns whether the location is on the given side.
        def is_side?(which)
          return @base_location == which
        end

        
      end
      
    end
  end
end

