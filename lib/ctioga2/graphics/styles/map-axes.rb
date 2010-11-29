# axes.rb: the style of one axis or edge 
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

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Styles


      # This class handles the display of a Z axis color map, in the
      # form of a colored bar with ticks and a label.
      class MapAxisStyle < AxisStyle

        # The actual color map
        attr_accessor :color_map
        
        # Zmin and Zmax boundaries
        attr_accessor :bounds

        # Size of the bar (not counting the label)
        attr_accessor :bar_size

        # Creates a new MapAxisStyle object at the given location with
        # the given style.
        def initialize()
          super()

          @bar_size = Types::Dimension.new(:dy, 2.4, :x)

          # Shifting away from the location.
          @shift = Types::Dimension.new(:dy, 0.1, :x)
        end

        def set_color_map(color_map, zmin, zmax)
          @bounds = [zmin, zmax]
          @color_map = color_map

        end

        def draw_axis(t)
          # Not beautiful at all
          size = Types::Dimension.new(:dy,extension(t))
          p t.frame_left
          @location.do_sub_frame(t, size) do
            t.fill_frame
          end
        end

        def set_bounds_for_axis(t, range = nil)
          # Useless here
        end

        # Draw the axis background lines:
        def draw_background_lines(t)
          # Nothing to do
        end

        # Code mostly coming from the
        def extension(t, style = nil)
          base = super

          base += @bar_size.to_text_height(t)
          return base
        end

        # Whether the axis is vertical or not
        def vertical?
          return @location.vertical?
        end

        protected


        # Returns: _ticks_shift_, _ticks_scale_ for the axis.
        #
        # \todo try something clever with the angles ?
        def get_ticks_parameters(t)
          # i = t.axis_information({'location' => @location.tioga_location})
          # retval = []
          # retval << (@tick_label_style.shift || i['shift'])
          # retval << (@tick_label_style.scale || i['scale'])

          # retval[0] += 1
          # return retval
        end
        
        # Returns an argument suitable for use for
        # FigureMaker#show_axis or FigureMaker#axis_information.
        #
        # For the log axis scale to work, tioga revision 543 is
        # absolutely necessary. It won't fail, though, without it.
        def get_axis_specification(t)
          # if @transform
          #   retval = compute_coordinate_transforms(t)
          # else
          #   retval = {}
          # end
          # if @offset 
          #   raise YetUnimplemented, "This has not been implemented yet"
          # else
          #   retval.
          #     update({'location' => @location.tioga_location,
          #              'type' => @decoration, 'log' => @log})
          #   return retval
          # end
        end

        # Setup coordinate transformations
        def compute_coordinate_transforms(t)
          # return unless @transform
          # # We'll proceed by steps...
          # i = t.axis_information({'location' => @location.tioga_location})
          # t.context do 
          #   if i['vertical']
          #     top,b = @transform.convert_to([t.bounds_top, t.bounds_bottom])
          #     l,r = t.bounds_left, t.bounds_right
          #   else
          #     top,b = t.bounds_top, t.bounds_bottom
          #     l,r = @transform.convert_to([t.bounds_left, t.bounds_right])
          #   end
          #   t.set_bounds([l,r,top,b])
          #   i = t.axis_information({'location' => @location.tioga_location})
          #   # Now, we have the location of everything we need.
          # end
          # # In the following, the || are because of a fix in Tioga
          # # r545
          # return { 'labels' => i['labels'], 
          #   'major_ticks' => @transform.
          #   convert_from(i['major_ticks'] || i['major']),
          #   'minor_ticks' => @transform.
          #   convert_from(i['minor_ticks'] || i['minor'] )
          # }
        end
      end

      ZAxisStyle = FullAxisStyle.dup
    end
  end
end
