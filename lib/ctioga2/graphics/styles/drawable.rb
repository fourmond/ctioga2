# drawable.rb: style objects pertaining to drawable objects.
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

    # All the styles
    module Styles

      # This class represents a plain line style.
      class LineStyle < BasicStyle
        # The line style
        typed_attribute :style, 'line-style'

        # The line width
        typed_attribute :width, 'float'

        # Sets the stroke style to a FigureMaker object, _t_.
        def set_stroke_style(t)
          t.line_type = @style if @style
          t.line_width = @width if @width
        end

        # Draws a line according with this style
        def draw_line(t, x1, y1, x2, y2)
          t.context do 
            set_stroke_style(t)
            t.stroke_line(x1, y1, x2, y2)
          end
        end
      end

      # This class represents all the stylistic information to stroke
      # a Tioga path.
      class StrokeStyle < LineStyle
        # The color
        typed_attribute :color, 'color-or-false'
        
        # Sets the stroke style to a FigureMaker object, _t_.
        def set_stroke_style(t)
          t.stroke_color = @color if @color
          super
        end

      end

      # This class represents all the stylistic information to draw a
      # Marker.
      #
      # \todo many things are still missing here...
      # 
      # * in particular, angles could be handled here, and they could
      #   be handled directly in the marker specification...
      class MarkerStyle < BasicStyle

        # The color
        typed_attribute :color, 'color'
        
        # The marker
        typed_attribute :marker, 'marker'

        # The marker scale
        typed_attribute :scale, 'float'

        # Shows the marker at a given location/set of locations.
        # 
        # \p override is a hash that can override part of the
        # dictionnary specification.
        def draw_markers_at(t, x, y, override = nil)
          t.context do
            ## \todo allow custom line types for markers ?
            t.line_type = LineStyles::Solid
            dict = { 
              'marker' => @marker, 
              'color' => @color
            }
            if x.is_a? Numeric
              dict['x'] = x
              dict['y'] = y
            else
              dict['Xs'] = x
              dict['Ys'] = y
            end

            if @scale
              dict['scale'] = @scale
            end
            if override
              dict.merge!(override)
            end
            t.show_marker(dict)
          end
        end
      end

    end
  end
end

