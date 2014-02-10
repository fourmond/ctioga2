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

        LocationsReorientMargins = {
          :left => [1,0,3,2],
          :right => [0,1,2,3],
          :top => [2,3,1,0],
          :bottom => [3,2,0,1]
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

        # Returns the orientation away from the graph
        def orientation
          if vertical?
            return :x
          else
            return :y
          end
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

        # Takes a set of margins, expressed in relative terms, ie
        # * _close_ (the margins on the side next to the graph),
        # * _away_ (on the other side),
        # * _aleft_ (on the left going away from the graph) and
        # * _aright_ (on the right going away from the graph)
        # into a left,right,top,bottom suitable for standards margins calls.
        def reorient_margins(close, away, aleft, aright)
          a = [close, away, aleft, aright]
          return LocationsReorientMargins[@base_location].map do |i|
            a[i]
          end
        end

        # Returns the margins argument suitable for sending to
        # set_subframe to paint within the region defined by the given
        # size at the given position.
        # 
        # _size_ is a Dimension object.
        def frame_margins_for_size(t, size)
          margins = Dobjects::Dvector[*LocationBaseMargins[@base_location]]
          ## @todo handle the case of at Y and at X
          dim = size.to_frame(t, orientation)

          add = Dobjects::Dvector[*LocationMarginMultiplier[@base_location]]
          add.mul!(dim)
          margins += add
          return margins
        end

        def do_sub_frame(t, size) 
          margins = frame_margins_for_size(t, size)

          ## @todo This is should integrate some common class.
          left = t.convert_frame_to_page_x(margins[0])
          right = t.convert_frame_to_page_x(1 - margins[1])
          top = t.convert_frame_to_page_y(1 - margins[2])
          bottom = t.convert_frame_to_page_y(margins[3])

          # Ensure that we don't have coords outside of the page range
          # because of rounding problems:
          left = 0.0 if left < 0
          bottom = 0.0 if bottom < 0
          right = 1.0 if right > 1
          top = 1.0 if top > 1

          t.context do 
            t.set_frame_sides(left, right, top, bottom)
            yield
          end
        end

        # Creates a location from the given text
        #
        # So far, no real parsing
        def self.from_text(str)
          loc = nil
          case str
          when /^\s*(left|right|top|bottom|at_y_origin|at_x_origin)\s*$/i
            loc = $1.downcase.to_sym
          when /^s*(x|y)0\s*$/i
            loc = "at_#{$1}_origin".downcase.to_sym
          end
          if ! loc
            raise "Unkown spec for axis location: '#{str}'"
          end
          return PlotLocation.new(loc)
        end

        
      end

      # Something meant to be fed to PlotStyle#get_axis_style
      LocationType = CmdType.new('location', { :type => :function_based,
                                 :class => Graphics::Types::PlotLocation
                                 }, <<EOD)
A position on the plot, referenced with respect to the sides. Can be:
 * @left@
 * @right@
 * @top@
 * @bottom@
 * @x0@, for the @x = 0@ position
 * @y0@, for the @y = 0@ position

In addition, there will one day be the possibility to specify an 
offset from these locations. But that is still something to do.
EOD


      
    end
  end
end

