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

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    # All the styles
    module Styles

      # This class represents the stylistic information necessary to
      # draw an error bar. It derives from StrokeStyle, as it is
      # essentially a stroke.
      class ErrorBarStyle < StrokeStyle

        # The error bar style. For now, not much here.
        attr_accessor :style

        # Shows an error bar with the appropriate stylistic
        # information. _x_ and _y_ are the coordinates of the data
        # point. The corresponding _min_ and _max_ are the minimum and
        # maximum values for the error bars. If either is _nil_, no
        # error bar on that direction is drawn.
        #
        # \todo maybe make provisions (one day) for complex error bars
        # showing min/max and stddev as well ?
        def show_error_bar(t, x, xmin, xmax, y, ymin, ymax)
          d = { 'x' => x,
            'y' => y,
            'color' => @color || Tioga::ColorConstants::Black,
            'line_width' => @width || 1.0,
          }
          has = false
          if (xmin && xmax && (xmax - xmin != 0))
            d['dx_plus'] = xmax - x
            d['dx_minus'] = x - xmin
            has = true
          end

          if (ymin && ymax && (ymax - ymin != 0))
            d['dy_plus'] = ymax - y
            d['dy_minus'] = y - ymin
            has = true
          end
          # We won't draw something when there isn't anything to draw
          # !
          if(has)
            t.show_error_bars(d)
          end
        end
      end

    end
  end
end

