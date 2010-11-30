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
        include Tioga::FigureConstants
        
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

        # The color of the stroke for the lines of the axis
        attr_accessor :stroke_color


        # Creates a new AxisStyle object at the given location with
        # the given style.
        def initialize(location = nil, decoration = nil, label = nil)
          @location = Types::PlotLocation.new(location)
          @decoration = decoration

          @tick_label_style = FullTextStyle.new
          @axis_label = TextLabel.new(label)
          @log = false
        end

        # Draws the axis within the current plot. Boundaries are the
        # current plot boundaries. Also draw the #axis_label, if there
        # is one.
        #
        # \todo
        # * the offset mechanism, to place the axis away from the place
        #   where it should be...
        # * non-linear axes (or linear, for that matter, but with
        #   a transformation)
        def draw_axis(t)
          spec = get_axis_specification(t)
          # Add tick label style:
          spec.merge!(@tick_label_style.to_hash)
          if @stroke_color
            spec['stroke_color'] = @stroke_color
          end
          t.show_axis(spec)
          @axis_label.loc = @location
          default = vertical? ? 'ylabel' : 'xlabel'
          @axis_label.draw(t, default)
        end

        # Sets the current boundaries of the _t_ object to the _range_
        # SimpleRange object for the direction handled by the
        # AxisStyle, without touching the rest.
        def set_bounds_for_axis(t, range = nil)
          if ! range
            return
          end
          l,r,top,b = t.bounds_left, t.bounds_right, 
          t.bounds_top, t.bounds_bottom

          if self.vertical?
            b = range.first
            top = range.last
          else
            l = range.first
            r = range.last
          end
          t.set_bounds([l,r,top,b])
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

        # Returns the part of the #extension only due to the labels
        # (ticks and standard label).
        #
        # For now, it returns the same value as #extension, but that
        # might change
        def labels_only_extension(t, style = nil)
          ticks_shift, ticks_scale = *get_ticks_parameters(t)
          p [ticks_shift, ticks_scale]
          default =  vertical? ? 'ylabel' : 'xlabel'
          le = @axis_label.label_extension(t, default, @location)

          case @decoration
          when AXIS_WITH_MAJOR_TICKS_AND_NUMERIC_LABELS,
            AXIS_WITH_TICKS_AND_NUMERIC_LABELS
            te = ticks_shift * ticks_scale
          else
            te = 0
          end
          return Dobjects::Dvector[le,te].max * 
            (style ? style.text_scale || 1 : 1)
        end

        # Returns the extension of the axis (including tick labels and
        # labels if applicable) perpendicular to itself, in units of
        # text height (at scale = current text scale when drawing
        # axes).
        #
        # _style_ is a PlotStyle object containing the style
        # information for the target plot.
        #
        # \todo handle offset axes when that is implemented.
        def extension(t, style = nil)
          return labels_only_extension(t, style)
        end

        protected

        # Whether the axis is vertical or not
        def vertical?
          return @location.vertical?
        end

        # Returns: _ticks_shift_, _ticks_scale_ for the axis.
        #
        # \todo try something clever with the angles ?
        def get_ticks_parameters(t)
          i = t.axis_information({'location' => @location.tioga_location})
          retval = []
          retval << (@tick_label_style.shift || i['shift'])
          retval << (@tick_label_style.scale || i['scale'])

          retval[0] += 1
          return retval
        end
        
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
              update({'location' => @location.tioga_location,
                       'type' => @decoration, 'log' => @log})
            return retval
          end
        end

        # Setup coordinate transformations
        def compute_coordinate_transforms(t)
          return unless @transform
          # We'll proceed by steps...
          i = t.axis_information({'location' => @location.tioga_location})
          t.context do 
            if i['vertical']
              top,b = @transform.convert_to([t.bounds_top, t.bounds_bottom])
              l,r = t.bounds_left, t.bounds_right
            else
              top,b = t.bounds_top, t.bounds_bottom
              l,r = @transform.convert_to([t.bounds_left, t.bounds_right])
            end
            t.set_bounds([l,r,top,b])
            i = t.axis_information({'location' => @location.tioga_location})
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
        'transform' => CmdArg.new('bijection'),
        'location' => CmdArg.new('location'),
        'stroke_color' => CmdArg.new('color')
      }

      FullAxisStyle = PartialAxisStyle.dup
      FullAxisStyle['decoration'] = CmdArg.new('axis-decoration')
                       

    end
  end
end
