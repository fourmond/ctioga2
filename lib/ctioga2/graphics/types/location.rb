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

        # A few helper hashes to convert from sides to margins
        # @todo won't work for origins.
        LocationBaseMargins = {
          :left => [0,1,0,0],
          :right => [1,0,0,0],
          :bottom => [0,0,1,0],
          :top => [0,0,0,1]
        }

        # Multiply this by the frame dimension in the correct
        # direction to get the frame margins.
        LocationMarginMultiplier = {
          :left => [-1,0,0,0],
          :right => [0,-1,0,0],
          :bottom => [0,0,0,-1],
          :top => [0,0,-1,0]
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

        # Returns the margins argument suitable for sending to
        # set_subframe to paint within the region defined by the given
        # size at the given position.
        # 
        # _size_ is a Dimension object.
        def frame_margins_for_size(t, size)
          margins = Dobjects::Dvector[*LocationBaseMargins[@base_location]]
          ## @todo handle the case of at Y and at X
          dim = size.to_frame(t, if vertical?
                                   :y
                                 else
                                   :x
                                 end
                              )
          add = Dobjects::Dvector[*LocationMarginMultiplier[@base_location]]
          add.mul!(dim)
          margins += add
          return margins
        end

        def do_sub_frame(t, size) 
          margins = frame_margins_for_size(t, size)
          # Now, convert to page coordinates ?
          ## @todo This is really ugly, and should probably integrate
          ## some common class.
          left = t.convert_frame_to_page_x(margins[0])
          right = t.convert_frame_to_page_x(1 - margins[1])
          top = t.convert_frame_to_page_y(1 - margins[2])
          bottom = t.convert_frame_to_page_y(margins[3])
          t.context do 
            t.set_frame_sides(left, right, top, bottom)
            yield
          end
        end

        # Creates a location from the given text
        #
        # So far, no real parsing
        def self.from_text(str)
          str.gsub!(/-/,"_")
          return PlotLocation.new(str.to_sym)
        end

        
      end
      
    end
  end
end

