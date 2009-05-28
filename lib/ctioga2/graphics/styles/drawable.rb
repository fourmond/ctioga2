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

      # This class represents all the stylistic information to stroke
      # a Tioga path.
      class StrokeStyle < BasicStyle
        # The color
        attr_accessor :color
        
        # The line style
        attr_accessor :style

        # The line width
        attr_accessor :width

        # Sets the stroke style to a FigureMaker object, _t_.
        def set_stroke_style(t)
          t.stroke_color = @color if @color
          t.line_type = @style if @style
          t.line_width = @width if @width
        end
      end

      # This class represents all the stylistic information to draw a
      # Marker.
      #
      # TODO: many things are still missing here...
      class MarkerStyle < BasicStyle

        # The color
        attr_accessor :color
        
        # The marker
        attr_accessor :marker

        # The marker scale
        attr_accessor :scale

        # Shows the marker at a given location/set of locations.
        def draw_markers_at(t, x, y)
          if x.is_a? Numeric
            x = Dvector[x]
            y = Dvector[y]
          end
          t.context do
            # Always with line style solid (though that could change ?)
            t.line_type = LineStyles::Solid
            dict = { 
              'Xs' => x, 'Ys' => y,
              'marker' => @marker, 
              'color' => @color
            }
            if @scale
              dict['scale'] = @scale
            end
            t.show_marker(dict)
          end
        end
      end

    end
  end
end

