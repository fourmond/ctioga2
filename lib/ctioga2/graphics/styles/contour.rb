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

        # The overall number of ticks (including minor ticks when
        # there is). May be approximative
        typed_attribute :number, 'integer'

        # Whether or not to "stick" to natural numbers for the 
        typed_attribute :use_naturals, 'boolean'

        # Number of subticks
        typed_attribute :minor_number, 'integer'

        # Relative scale of the minor ticks. Used if the absolute
        # width is not specified.
        typed_attribute :minor_scale, 'float'

        # Line style of minor ticks.
        sub_style :minor, LineStyle

        def initialize()
          @number = 20
          @use_naturals = true
          @minor_number = 4
          @minor_scale = 0.6
        end

        # Computes and plots the contours according to the style,
        # using the given color map.
        def plot_contours(t, table, zmin, zmax, color_map)

          ticks = []
          minor_ticks = []

          if @use_naturals
            bdz = (zmax - zmin)*@minor_number/@number
            bdz = Utils.closest_subdivision(bdz)

            zb = ((zmin/bdz).ceil) * bdz
            z = zb
            i = 0
            while z < zmax
              ticks << z
              z = zb + i*bdz
              i += 1
            end

            sbdz = bdz/@minor_number
            sbdz = Utils.closest_subdivision(sbdz, false)

            zb = ((zmin/sbdz).ceil) * sbdz
            z = zb
            i = 0
            idx = 0
            while z < zmax
              if ticks[idx] == z
                idx += 1
              else
                minor_ticks << z
              end
              i += 1
              z = zb + i*sbdz
            end
          else
            dz = (zmax - zmin)/@number
            @number.times do |i|
              ticks << zmin + (i + 0.5) * dz
            end
          end

          for lvl in ticks
            t.context do
              t.stroke_color = color_map.z_color(lvl, zmin, zmax)
              contour = make_contour(table, lvl)
              t.append_points_with_gaps_to_path(*contour)
              t.stroke
            end
          end

          # Minor ticks, when applicable !
          t.context do 
            t.line_width = t.line_width * @minor_scale
            @minor.set_stroke_style(t) if @minor
            for lvl in minor_ticks
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

