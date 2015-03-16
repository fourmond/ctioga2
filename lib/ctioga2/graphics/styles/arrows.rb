# arrows.rb: style objects for lines and arrows
# copyright (c) 2012 by Vincent Fourmond
  
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

      # This class represents an arrow

      class ArrowStyle < StrokeStyle

        # This probably should end up being a marker_style sub_style

        for e in [:head, :tail]
          typed_attribute "#{e}_marker".to_sym, 'marker'
          typed_attribute "#{e}_scale".to_sym, 'float'
          typed_attribute "#{e}_angle".to_sym, 'float'
          typed_attribute "#{e}_color".to_sym, 'color'
        end

        TiogaDefaults = {
          'head_marker' => Tioga::MarkerConstants::Arrowhead,
          'tail_marker' => Tioga::MarkerConstants::BarThin
        }

        def old_draw_arrow(t, x1, y1, x2, y2)
          dict = self.to_hash
          dict.rename_key('width', 'line_width')
          dict.rename_key('style', 'line_style')
          dict['head'] = [x2,y2]
          dict['tail'] = [x1,y1]
          for w in %w(head tail)
            if dict["#{w}_marker"] == false
              dict["#{w}_marker"] = "None"
            end
          end
          t.show_arrow(dict)
        end


        # Draws an arrow.
        def draw_arrow(t, x1, y1, x2, y2)
          dx = x2 - x1
          dy = y2 - y1

          angle = Types::Dimension.get_angle(t, dx, dy)

          len = Types::Dimension.get_distance(t, dx, dy)

          rs = symbol_size(t, "head")
          ls = symbol_size(t, "tail")

          x1n, y1n, x2n, y2n = *Types::Dimension::adjust_line(t, x1, y1, x2, y2, -ls, -rs)

          # Must shorten the path first...
          sv = t.line_cap
          if sv != Tioga::FigureConstants::LINE_CAP_BUTT
            t.line_cap = Tioga::FigureConstants::LINE_CAP_BUTT
          end
          draw_line(t, x1n, y1n, x2n, y2n)
          if sv != Tioga::FigureConstants::LINE_CAP_BUTT
            t.line_cap = sv
          end

          # Then, draw the arrow heads/tails
          draw_symbol(t, 'head', angle, x2, y2)
          draw_symbol(t, 'tail', angle - 180, x1, y1)
          
        end

        protected

        # Return the dimension of the arrow size
        def symbol_size(t, name)
          sz = Types::Dimension.new(:dy,self.send("#{name}_scale") || 1.0)
          sz.value *= case just(name)
                     when Tioga::FigureConstants::CENTERED
                       0
                     when Tioga::FigureConstants::RIGHT_JUSTIFIED
                       0.5
                     end
          return sz
        end

        def just(name)
          mkr = self.send("#{name}_marker")
          if mkr == Tioga::MarkerConstants::Arrowhead or
            mkr == Tioga::MarkerConstants::ArrowheadOpen
            Tioga::FigureConstants::RIGHT_JUSTIFIED
          else
            Tioga::FigureConstants::CENTERED
          end
        end

        # Draw the arrow symbol for the given name (head or tail),
        # with the given base angle and at the given position
        def draw_symbol(t, name, angle, x, y)
          hsh = {}
          for k in %w(marker scale color angle)
            tmp = self.send("#{name}_#{k}")
            if tmp
              hsh[k] = tmp
            end
          end
          mkr = hsh['marker']
          if ! mkr  or  mkr == 'None'
            return
          end

          hsh['angle'] ||= 0
          hsh['angle'] += angle

          hsh['x'] = x
          hsh['y'] = y

          # Color defaults to line color
          if @color and !hsh.key?('color')
            hsh['color'] = @color
          end

          hsh['justification'] = just(name)
          t.show_marker(hsh)
        end

      end
    end
  end
end

