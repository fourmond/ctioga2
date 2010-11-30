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

        # Space to be left between the graph and the beginning of the
        # graph
        attr_accessor :shift

        # Space to be left on the side
        attr_accessor :padding

        # Creates a new MapAxisStyle object at the given location with
        # the given style.
        def initialize()
          super()

          @bar_size = Types::Dimension.new(:dy, 2.4, :x)

          # Shifting away from the location.
          @shift = Types::Dimension.new(:dy, 0.3, :x)

          ## @todo maybe use different padding for left and right ?
          @padding = Types::Dimension.new(:dy, 0.5, :x)

          @decoration = AXIS_WITH_TICKS_AND_NUMERIC_LABELS
        end

        def set_color_map(color_map, zmin, zmax)
          @bounds = [zmin, zmax]
          @color_map = color_map

        end

        def draw_axis(t)
          # Not beautiful at all
          size = Types::Dimension.new(:dy, extension(t))
          label_size = 
            Types::Dimension.new(:dy, labels_only_extension(t, style = nil))

          @location.do_sub_frame(t, size) do
            # This is a necessary workaround for a small bug
            t.set_subframe([0,0,0,0])
            # Here, do the correct setup, using a MarginsBox:
            # * correctly setup the axes/edges
            # * handle the sides correctly.
            # * position the subplot within accordingly
            # * use draw_axis for the axis ?

            plot_box = Types::MarginsBox.
              new(*@location.reorient_margins(@shift, label_size, 
                                              @padding, @padding))

            # We wrap the call within a subplot
            t.subplot(plot_box.to_frame_margins(t)) do
              t.set_bounds([0, 1, @bounds.last, @bounds.first])
              t.context do 
                t.clip_to_frame
                t.axial_shading(
                                'start_point' => [0.5, @bounds.first],
                                'end_point' => [0.5, @bounds.last],
                                'colormap' => @color_map.
                                to_colormap(t, @bounds.first,
                                            @bounds.last).first
                                )
              end
            end

            # # xmin = 0; xmax = 1; xmid = 0.5
            # # t.xaxis_type = AXIS_LINE_ONLY
            # # t.xaxis_loc = BOTTOM
            # # t.top_edge_type = AXIS_LINE_ONLY
            # # t.yaxis_loc = t.ylabel_side = RIGHT
            # # t.yaxis_type = AXIS_WITH_TICKS_AND_NUMERIC_LABELS
            # # t.left_edge_type = AXIS_WITH_TICKS_ONLY
            # # t.ylabel_shift += 0.5
            # # t.yaxis_major_tick_length *= 0.6
            # # t.yaxis_minor_tick_length *= 0.5
            # # t.do_box_labels(nil, nil, 'Log Pressure')
            # t.show_plot('boundaries' => ) do
            #   t.axial_shading(
            #                   'start_point' => [0.5, @bounds.first],
            #                   'end_point' => [0.5, @bounds.last],
            #                   'colormap' => @color_map.
            #                   to_colormap(t, @bounds.first,
            #                               @bounds.last).first
            #                   )
            # end
          end
        end

        def set_bounds_for_axis(t, range = nil)
          # Useless here
        end

        # Draw the axis background lines:
        def draw_background_lines(t)
          # Nothing to do
        end

        def extension(t, style = nil)
          base = super(t, style)

          base += @bar_size.to_text_height(t)
          return base
        end

        # Whether the axis is vertical or not
        def vertical?
          return @location.vertical?
        end

      end
      ZAxisStyle = FullAxisStyle.dup
    end
  end
end