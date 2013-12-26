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

        def draw_arrow(t, x1, y1, x2, y2)
          dict = self.to_hash
          dict.rename_key('width', 'line_width')
          dict.rename_key('style', 'line_style')
          dict['head'] = [x2,y2]
          dict['tail'] = [x1,y1]
          t.show_arrow(dict)
        end

      end
    end
  end
end

