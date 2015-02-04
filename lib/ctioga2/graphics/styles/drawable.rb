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

      # This class represents all the stylistic information necessary
      # to draw a line parallel to a certain direction, indicated by
      # an angle (default to horizontal)
      class OrientedLineStyle < StrokeStyle
        # The angle, in degrees.
        typed_attribute :angle, 'float'

        # The alignment of the line with respect to the point given.
        typed_attribute :origin, 'justification'

        # len is a dimension
        def draw_oriented_line(t, xo, yo, len)

          angle = @angle || 0.0

          dx,dy = *len.to_figure(t, angle)

          case @origin || Tioga::FigureConstants::LEFT_JUSTIFIED
          when Tioga::FigureConstants::LEFT_JUSTIFIED
            x1, y1 = xo, yo
            x2, y2 = xo + dx, yo + dy
          when Tioga::FigureConstants::CENTERED
            x1, y1 = xo - 0.5 * dx, yo - 0.5 * dy
            x2, y2 = xo + 0.5 * dx, yo + 0.5 * dy
          when Tioga::FigureConstants::RIGHT_JUSTIFIED
            x1, y1 = xo - dx, yo - dy
            x2, y2 = xo, yo
          end

          draw_line(t, x1, y1, x2, y2)
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

        # The marker
        typed_attribute :marker, 'marker'

        # The marker scale
        typed_attribute :scale, 'float'

        # The angle
        typed_attribute :angle, 'float'

        # The default for color
        typed_attribute :color, 'color-or-false'

        # The stroke color
        typed_attribute :stroke_color, 'color-or-false'

        # The fill color
        typed_attribute :fill_color, 'color-or-false'

        # The stroke width
        typed_attribute :width, 'float'

        

        # Shows the marker at a given location/set of locations.
        # 
        # \p override is a hash that can override part of the
        # dictionnary specification.
        def draw_markers_at(t, x, y, override = nil)
          return if (! @marker || @marker == 'None')

          dict = { 
            'marker' => @marker
          }
          if @width
            dict['stroke_width'] = @width
          end
          if !(@fill_color.nil?) || !(@stroke_color.nil?)
            dict['fill_color'] = @fill_color.nil? ? @color : @fill_color
            dict['stroke_color'] = @stroke_color.nil? ? @color : @stroke_color
            dict['rendering_mode'] = 
              if dict['fill_color']
                if dict['stroke_color']
                  Tioga::FigureConstants::FILL_AND_STROKE
                else
                  Tioga::FigureConstants::FILL
                end
              else
                Tioga::FigureConstants::STROKE
              end
            dict.strip_if_false!(%w{fill_color stroke_color})
          else
            dict['color'] = @color
            if ! @color
              return            # Nothing to do !
            end
          end
          if @angle
            dict['angle'] = @angle
          end
          
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
          t.context do
            ## \todo allow custom line types for markers ?
            t.line_type = LineStyles::Solid
            t.show_marker(dict)
          end
        end
      end

    end
  end
end

