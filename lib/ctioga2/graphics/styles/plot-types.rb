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

      StyleAspectRE = {
        /^marker[_-]color$/i => :marker_color,
        /^marker[_-](size|scale)$/i => :marker_scale,
      }

      StyleAspect = 
        CmdType.new('style-aspect',  {:type => :re_list,
                      :list => StyleAspectRE}, <<EOD)

This type designs which aspect of the style of a 
{command: xy-parametric} plot is controlled by a certain Z value.
It can take the following values:
 * @marker_color@: the color for the markers
 * @marker_size@/@marker_scale@: the size of the markers
EOD

      # This class defines how the Z values are converted into
      # stylistic information
      class ParametricPlotStyle < BasicStyle
        
        # What is the z1 axis
        typed_attribute :z1, 'style-aspect'

        # What is the z2 axis
        typed_attribute :z2, 'style-aspect'

        def initialize
          @z1 = :marker_color
        end

        def prepare
          @reversed = {}

          2.times do |i|
            val = self.send("z#{i+1}")
            if val
              @reversed[val] = i
              @needed = i+1
            end
          end
        end

        # The number of Z columns needed for the style. 
        def z_columns_needed
          return @needed || 0
        end

        # Returns the marker style for the given Z values.
        #
        # This will only work if #prepare has been called first !
        def marker_style(curve_style, zvalue, zmin, zmax)

          style = curve_style.marker.dup

          if @reversed[:marker_scale]
            idx = @reversed[:marker_scale]
            if idx < zvalue.size
              max_scale = curve_style.marker.scale || 1.0

              ## @todo Later on, when a min_marker_scale is provided,
              ## then the scale will be constrained between the min
              ## and max. For now, it is simply proportionnal to the
              ## absolute value of the largest.
              min_scale = curve_style.marker_min_scale

              zm = zmin[idx]
              zM = zmax[idx] 
              
              mm = zM.abs
              m2 = zm.abs
              mm = m2 if m2 > mm

              z = zvalue[idx]

              style.scale = if min_scale
                              min_scale + (max_scale - min_scale) * 
                                (z - zm)/(zM - zm)
                            else
                              zvalue[idx].abs/mm * max_scale
                            end
            end

          end

          if @reversed[:marker_color]
            idx = @reversed[:marker_color]
            if idx < zvalue.size
              style.color = curve_style.marker_color_map.z_color(zvalue[idx], 
                                                                 zmin[idx], 
                                                                 zmax[idx])
            end
          end

          return style

        end

      end

      CumulativeHistogramsType = 
        CmdType.new('cumulative-histograms',
                    {
                      :type => :integer,
                      :shortcuts => {
                        /next/i => :next,
                        /no|false/i => false
                      }
                    })


      # This class defines various informations about the look of
      # histograms.
      class HistogramStyle < BasicStyle 

        # Separation between the histograms inside a group of histogram
        typed_attribute :intra_sep, 'dimension'

        # Separation between the histograms of different groups
        typed_attribute :inter_sep, 'dimension'

        # Specs for cumulative 
        typed_attribute :cumulative, 'cumulative-histograms'

        def set_from_hash(hash, name = "%s")
          super

          if @cumulative == :next
            @last_neg ||= 0
            @last_neg -= 1
            @cumulative = @last_neg
          end
            
        end


      end
    end

  end
end

