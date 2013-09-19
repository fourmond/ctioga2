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

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    # All the styles
    module Styles
      BoxShapeRE = {
        /^square$/i => :square,
        /^round(ed)?$/i => :round,
      }

      BoxShape = 
        CmdType.new('box-shape', {:type => :re_list,
                      :list => BoxShapeRE}, <<EOD)
The shape of a box. It can be:
 * @square@ for a plain square box
 * @round@ for a rounded box
EOD

      # This class represents styles attached to a box
      #
      # @todo Add rounded corners and the like...
      class BoxStyle < StrokeStyle

        sub_style 'fill', FillStyle

        typed_attribute 'shape', 'box-shape'

        # Radius of rounded box
        typed_attribute 'radius', 'dimension'

        def initialize
          @shape = :square
          @radius = Types::Dimension::new(:dy, 1.0)
        end

        def prepare_path(t, x1, y1, x2, y2)
          case @shape
          when :square
            t.append_rect_to_path(x1, y1, x2 - x1, y2 - y1)
          when :round
            dx = @radius.to_figure(t, :x)
            dy = @radius.to_figure(t, :y)

            xl = x1
            xr = x2
            xl,xr = xr, xl if xl > xr

            yt = y1
            yb = y2
            yb,yt = yt,yb if yb > yt
            
            t.move_to_point(xl, yt - dy)
            t.append_curve_to_path(xl, yt - 0.5 * dy, # First control point
                                   xl + 0.5 * dx, yt, 
                                   xl + dx, yt)
            t.append_point_to_path(xr - dx, yt)
            t.append_curve_to_path(xr - 0.5 * dx, yt,
                                   xr, yt - 0.5 * dy, 
                                   xr, yt - dy)

            t.append_point_to_path(xr, yb + dy)
            t.append_curve_to_path(xr, yb + 0.5 * dy, # First control point
                                   xr - 0.5 * dx, yb, 
                                   xr - dx, yb)
            t.append_point_to_path(xl + dx, yb)
            t.append_curve_to_path(xl + 0.5 * dx, yb, # First control point
                                   xl, yb + 0.5 * dy, 
                                   xl, yb + dy)
            t.close_path
          else
            raise "Unknown box shape: #{@shape}"
          end
        end

        def draw_box(t, x1, y1, x2, y2)
          t.context do
            t.discard_path

            ## @todo Rounded rects!
            if fill && fill.color
              fill.setup_fill(t)
              prepare_path(t, x1, y1, x2, y2)
              fill.do_fill(t)
            end
            if color
              set_stroke_style(t)
              prepare_path(t, x1, y1, x2, y2)
              t.stroke
            end
          end

        end

        # Draws a box around the given box, leaving dx and dy
        # around. If _dy_ is omitted, it defaults to _dx_
        def draw_box_around(t, x1, y1, x2, y2, dx, dy = nil)
          dy ||= dx
          dx = dx.to_figure(t, :x)
          dy = dy.to_figure(t, :y)
          draw_box(t, x1 - dx, y1 + dy,
                   x2 + dx, y2 - dy)
        end

      end
    end
  end
end

