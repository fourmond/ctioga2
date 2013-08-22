# curve.rb: style objects pertaining to curves and other line drawings.
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

      # A class holding all the styles for a curve.
      #
      # \todo maybe for objects different than Curve2D, a subclass of
      # CurveStyle could be used ? This way, we could have clearly
      # separated legends and the like ?
      class CurveStyle < BasicStyle

        # The style of the line that is drawn, as a StrokeStyle. 
        sub_style :line, StrokeStyle

        # The style of markers that should be drawn, as a MarkerStyle.
        sub_style :marker, MarkerStyle

        # The text of the legend, if there is one.
        typed_attribute :legend, 'text'

        # The style of the error bars when needed, as a ErrorBarStyle.
        sub_style :error_bar, ErrorBarStyle

        # Filling of the curve, if applicable
        sub_style :fill, CurveFillStyle

        # Details of the location of the curve, a LocationStyle object.
        #
        # The _true_ bit makes sure @location is always created.
        sub_style :location, LocationStyle, nil, true

        # Whether in a region plot, the curve should be above or below
        # the filled region.
        typed_attribute :region_position, "region-side"

        # A path style.
        #
        # @todo Ideas for a path style include
        # - plain lines
        # - impulses ?
        # - splines
        # See gnuplot help for "plot with" for inspiration.
        #
        # For now completely useless !
        typed_attribute :path_style, 'text'

        # A colormap for strokes (only for XYZ data)
        #
        # @todo There should be a very clear way to mark curve style
        # elements which are specific to certain kinds of plots (and
        # warn the user about misuses ?)
        typed_attribute :color_map, 'colormap'

        # The name of an axis to create to use for the display of the
        # Z scale.
        #
        # @todo specify the behaviour when the axis exists.
        typed_attribute :zaxis, 'text'

        # A colormap for markers (only for XYZ data) 
        typed_attribute :marker_color_map, 'colormap'

        # Whether the XY display should split on NaN values (wherever)
        typed_attribute :split_on_nan, 'boolean'


        # Style of contour plots
        sub_style :contour, ContoursStyle

        # The following attributes are not styles but here to help

        # The object attached to this style. It is set by
        # Generator#curve_from_dataset
        attr_accessor :target

        # True if a line should be drawn.
        def has_line?
          return @line && @line.style
        end

        # True if markers should be drawn
        def has_marker?
          return @marker && @marker.marker
        end

        # True if there is one legend to be drawn for this object.
        def has_legend?
          return @legend
        end

        # Draws a legend pictogram that fills up the whole current
        # frame.
        #
        # \todo add more elements to the pictogram in case of more
        # complex things.
        #
        # @todo Most probably the legend pictogram should be done by
        # the curve directly rather than by the style.
        def draw_legend_pictogram(t)
          t.context do
            case @target
            when Elements::Curve2D
              if has_line?
                @line.set_stroke_style(t)
                t.stroke_line(0.0, 0.5, 1.0, 0.5)
              end
              if has_marker?
                @marker.draw_markers_at(t, [0.5], [0.5])
              end
            when Elements::Parametric2D
              if has_marker? && @marker_color_map
                colors = @marker_color_map.colors.uniq
                i = 1
                total = colors.size + 1.0
                for c in colors
                  @marker.draw_markers_at(t, [i/total], [0.5], 
                                          {'color' => c} )
                  i += 1
                end
              end
            end
          end
        end


      end
    end
  end
end

