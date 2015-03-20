# scope.rb: containers that provide translation and scaling capacities
# copyright (c) 2015 by Vincent Fourmond
  
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

      # This style represents a scope, ie something that translates
      # (first) and scales (second) figure coordinates.
      class ScopeStyle < BasicStyle

        typed_attribute 'xshift', 'dimension'
        typed_attribute 'xscale', 'float'

        typed_attribute 'yshift', 'dimension'
        typed_attribute 'yscale', 'float'


        def initialize
        end

        # applies the transformation to the current figure coordinates
        def apply_to_figure(t)
          bl = t.bounds_left
          br = t.bounds_right
          bt = t.bounds_top
          bb = t.bounds_bottom

          if @xshift
            dx = @xshift.to_figure(t,:x)
            bl -= dx
            br -= dx
          end

          if @yshift
            dy = @yshift.to_figure(t,:y)
            bt -= dy
            bb -= dy
          end

          if @xscale
            bl, br = *Utils::scale_segment(bl, br, 1/@xscale)
          end
          if @yscale
            bt, bb = *Utils::scale_segment(bt, bb, 1/@yscale)
          end

          t.set_bounds([bl, br, bt, bb])
        end

      end
    end
  end
end

