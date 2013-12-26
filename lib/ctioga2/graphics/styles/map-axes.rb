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

  module Graphics

    module Styles


      # This class handles the display of a Z axis color map, in the
      # form of a colored bar with ticks and a label.
      class MapAxisStyle < AxisStyle

        # The actual color map
        attr_accessor :color_map
        
        # Zmin and Zmax boundaries
        typed_attribute :bounds, "float-range"

        # Size of the bar (not counting the label)
        typed_attribute :bar_size, 'dimension'

        # Space to be left between the graph and the beginning of the
        # graph
        typed_attribute :bar_shift, 'dimension'

        # Space to be left on the side
        typed_attribute :padding, 'dimension'

        # Creates a new MapAxisStyle object at the given location with
        # the given style.
        def initialize()
          super()

          @bar_size = Types::Dimension.new(:dy, 2, :x)

          # Shifting away from the location.
          @bar_shift = Types::Dimension.new(:dy, 0.3, :x)

          ## @todo maybe use different padding for left and right ?
          @padding = Types::Dimension.new(:dy, 0.5, :x)

          @decoration = AXIS_WITH_TICKS_AND_NUMERIC_LABELS

          # To be implemented one day...
          @other_side_decoration = nil
        end

        def set_color_map(color_map, zmin, zmax)
          @bounds = [zmin, zmax]
          @color_map = color_map

        end

        def draw_axis(t)
          # Not beautiful at all
          size = Types::Dimension.new(:dy, extension(t), 
                                      @location.orientation)
          label_size = 
            Types::Dimension.new(:dy, labels_only_extension(t, style = nil),
                                 @location.orientation)

          @location.do_sub_frame(t, size) do
            # This is a necessary workaround for a small bug
            t.set_subframe([0,0,0,0])
            # Here, do the correct setup, using a MarginsBox:
            # * correctly setup the axes/edges
            # * handle the sides correctly.
            # * position the subplot within accordingly
            # * use draw_axis for the axis ?

            plot_box = Types::MarginsBox.
              new(*@location.reorient_margins(@bar_shift, label_size, 
                                              @padding, @padding))

            # We wrap the call within a subplot
            t.subplot(plot_box.to_frame_margins(t)) do
              bounds = if @location.vertical?
                         [0, 1, @bounds.last, @bounds.first]
                       else
                         [@bounds.first, @bounds.last, 0, 1]
                       end
              t.set_bounds(bounds)
              t.context do 
                t.clip_to_frame
                cmap, zmin, zmax = *@color_map.to_colormap(t, @bounds.first,
                                                          @bounds.last)

                sp = [0.5, zmin]
                ep = [0.5, zmax]
                if ! @location.vertical?
                  sp.reverse!
                  ep.reverse!
                end
                t.axial_shading(
                                'start_point' => sp,
                                'end_point' => ep,
                                'colormap' => cmap
                                )
              end
              ## @todo handle axis color ?
              t.stroke_frame
              ## @todo potentially handle decorations for the other
              ## side too.

              ## @todo This is a ugly hack, but Ruby doesn't allow a
              ## clean one. Though
              ## http://stackoverflow.com/questions/1251178/calling-another-method-in-super-class-in-ruby
              ## seems like the way to go ! To be implemented one day.
              self.class.superclass.instance_method(:draw_axis).
                bind(self).call(t)
              
            end

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

          base += @bar_size.to_text_height(t, @location.orientation)
          base += @bar_shift.to_text_height(t, @location.orientation)
          return base
        end

        # Whether the axis is vertical or not
        def vertical?
          return @location.vertical?
        end

      end
      # @todo This naming doesn't look that good, honestly
      ZAxisStyle = MapAxisStyle.options_hash()

    end
  end
end
