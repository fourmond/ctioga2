# contour.rb: the style of a contour plot
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


      # The base for a contour plot
      class BaseContourStyle < BasicStyle
        
        # Whether or not to use conrec for the contour computation
        typed_attribute :conrec, 'boolean'

        def make_contour(table, level, opts = {})
          if @conrec && (! opts.key? 'method')
            opts['method'] = 'conrec'
          end
          return table.make_contour(level, opts)
        end
        
      end


      # This class expands on the previous one to provide for
      # mechanisms to draw many related contour plots.
      class ContoursStyle < BaseContourStyle

        typed_attribute :number, 'integer'

        # Computes and plots the contours according to the style,
        # using the given color map.
        def plot_contours(t, table, zmin, zmax, color_map)
          nb = @number || 20
          
          dz = (zmax - zmin)/nb

          nb.times do |i|
            lvl = zmin + (i + 0.5) * dz
            t.context do
              t.stroke_color = color_map.z_color(lvl, zmin, zmax)
              contour = make_contour(table, lvl)
              t.append_points_with_gaps_to_path(*contour)
              t.stroke
            end
          end

        end
      end
    end
  end
end

