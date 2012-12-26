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

      # This class represents styles attached to a box
      class BoxStyle < StrokeStyle

        sub_style 'fill', FillStyle

        def draw_box(t, x1, y1, x2, y2)
          t.context do
            t.discard_path

            ## @todo Rounded rects!
            if fill && fill.color
              fill.setup_fill(t)
              t.append_rect_to_path(x1, y1, x2 - x1, y2 - y1)
              fill.do_fill(t)
            end
            if color
              set_stroke_style(t)
              t.append_rect_to_path(x1, y1, x2 - x1, y2 - y1)
              t.stroke
            end
          end

        end

      end
    end
  end
end

