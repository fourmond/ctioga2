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

      # The style of an axis or an egde of the plot. Unlike tioga,
      # ctioga2 does not make any difference.
      class AxisStyle < BasicStyle
        
        # The type of the edge/axis. Any of the Tioga constants:
        # AXIS_HIDDEN, AXIS_LINE_ONLY, AXIS_WITH_MAJOR_TICKS_ONLY,
        # AXIS_WITH_TICKS_ONLY,
        # AXIS_WITH_MAJOR_TICKS_AND_NUMERIC_LABELS, and
        # AXIS_WITH_TICKS_AND_NUMERIC_LABELS.
        attr_accessor :decoration
        
        # The position of the axis. Can be one of :left, :right, :top,
        # :bottom, :at_y_origin or :at_x_origin.
        attr_accessor :location

        # Offset of the axis with respect to its normal position. It
        # is counted *away* from the graph. It is either a
        # Types::Dimension object or _nil_.
        attr_accessor :offset

        # The background lines for the given axis. _nil_ for nothing,
        # or a StrokeStyle object if we want to draw something.
        attr_accessor :background_lines

        # The style of the tick labels
        attr_accessor :tick_label_style

        # The label of the axis, if there is one
        attr_accessor :axis_label

        # Whether the axis should be log scale or not
        attr_accessor :log

        # Transform: a Types::Bijection object specifying a coordinate
        # transformation for the axis.
        attr_accessor :transform


        # Creates a new AxisStyle object at the given location with
        # the given style.
        def initialize(location = nil, decoration = nil, label = nil)
          @location = location
          @decoration = decoration

          @tick_label_style = BaseTextStyle.new
          @axis_label = TextLabel.new(label)
          @log = false
        end

        # Draws the axis within the current plot. Boundaries are the
        # current plot boundaries. Also draw the #axis_label, if there
        # is one.
        #
        # TODO:
        # * the offset mechanism, to place the axis away from the place
        #   where it should be...
        # * non-linear axes (or linear, for that matter, but with
        #   a transformation)
        def draw_axis(t)
          spec = get_axis_specification(t)
          # Add tick label style:
          spec.merge!(@tick_label_style.to_hash)
          t.show_axis(spec)
          @axis_label.loc = LocationToTiogaLocation[@location]
          @axis_label.draw(t)
        end

        # Draw the axis background lines:
        def draw_background_lines(t)
          if @background_lines
            # First, getting major ticks location from tioga
            info = t.axis_information(get_axis_specification(t))

            if info['vertical']
              x0 = t.bounds_left
              x1 = t.bounds_right
            else
              y0 = t.bounds_bottom
              y1 = t.bounds_top
            end
            t.context do
              @background_lines.set_stroke_style(t)
              values = info['major_ticks'] || info['major']
              for val in values
                if info['vertical']
                  t.stroke_line(x0, val, x1, val)
                else
                  t.stroke_line(val, y0, val, y1)
                end
              end
            end
          end
        end

        # Returns the AxisStyle object corresponding to the named axis
        # in the current plot.
        def self.current_axis_style(plotmaker, spec)
          return PlotStyle.current_plot_style(plotmaker).
            get_axis_style(spec)
        end

        protected
        
        # Returns an argument suitable for use for
        # FigureMaker#show_axis or FigureMaker#axis_information.
        #
        # For the log axis scale to work, tioga revision 543 is
        # absolutely necessary. It won't fail, though, without it.
        def get_axis_specification(t)
          if @transform
            retval = compute_coordinate_transforms(t)
          else
            retval = {}
          end
          if @offset 
            raise YetUnimplemented, "This has not been implemented yet"
          else
            retval.
              update({'location' => 
                       LocationToTiogaLocation[@location],
                       'type' => @decoration, 'log' => @log})
            return retval
          end
        end

        # Setup coordinate transformations
        def compute_coordinate_transforms(t)
          return unless @transform
          # We'll proceed by steps...
          i = t.axis_information({'location' => 
                                   LocationToTiogaLocation[@location]})
          t.context do 
            if i['vertical']
              top,b = @transform.convert_to([t.bounds_top, t.bounds_bottom])
              l,r = t.bounds_left, t.bounds_right
            else
              top,b = t.bounds_top, t.bounds_bottom
              l,r = @transform.convert_to([t.bounds_left, t.bounds_right])
            end
            t.set_bounds([l,r,top,b])
            i = t.axis_information({'location' => 
                                     LocationToTiogaLocation[@location]})
            # Now, we have the location of everything we need.
          end
          # In the following, the || are because of a fix in Tioga
          # r545
          return { 'labels' => i['labels'], 
            'major_ticks' => @transform.
            convert_from(i['major_ticks'] || i['major']),
            'minor_ticks' => @transform.
            convert_from(i['minor_ticks'] || i['minor'] )
          }
        end


       
      end

      PartialAxisStyle = {
        'transform' => CmdArg.new('bijection')
      }

      FullAxisStyle = PartialAxisStyle.dup
      FullAxisStyle['decoration'] = CmdArg.new('axis-decoration')
                       

    end
  end
end
