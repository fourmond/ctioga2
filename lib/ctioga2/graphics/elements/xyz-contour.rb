# xyz-contour.rb: contour plot of a xyz set of data
# copyright (c) 2013 by Vincent Fourmond

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details (in the COPYING file).

require 'ctioga2/utils'
require 'ctioga2/log'

require 'Dobjects/Function'


module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Elements

      # This class displays a XYZ element using contour lines.
      class XYZContour  < TiogaElement

        include Log
        include Dobjects

        # The Data::Dataset object that should get plotted.
        attr_accessor :dataset

        # A Styles::CurveStyle object saying how the curve should be
        # drawn.
        #
        # Some of the elements will be overridden.
        attr_accessor :curve_style

        # The IndexedTable object representing the underlying data
        attr_accessor :table


        undef :location=, :location
        
        # Creates a new XYZContour object with the given _dataset_ and
        # _style_.
        #
        # Lots of code in common with XYZMap
        def initialize(dataset, style = nil)
          @dataset = dataset
          @curve_style = style
          prepare_data
        end

        # Prepares the internal storage of the data, from the @dataset
        def prepare_data
          @table = @dataset.indexed_table
        end
        
        protected :prepare_data

        # Returns the LocationStyle object of the curve. Returns the
        # one from #curve_style.
        def location
          return @curve_style.location
        end

        # Returns the Types::Boundaries of this curve.
        def get_boundaries
          return @table.xy_boundaries
        end
        

        ## Actually draws the curve
        def real_do(t)
          debug { "Plotting curve #{inspect}" }
          t.context do
            # Of course, there are still quite a few things to do
            # ;-)...

            # Ideas: for leaving things out, I may have to use min_gt
            # along with masking.

            ## @todo handle non-homogeneous XY maps.
            
            @curve_style.color_map ||= 
              Styles::ColorMap.from_text("Red--Green")
            
            if @curve_style.zaxis
              begin
                @parent.style.get_axis_style(@curve_style.zaxis).
                  set_color_map(@curve_style.color_map, 
                                @table.table.min,
                                @table.table.max)
              rescue
                error { "Could not set Z info to non-existent axis #{@curve_style.zaxis}" }
              end
            end

            # Computation of equally spaced level lines
            nb = 20

            zmin = @table.table.min
            zmax = @table.table.max
            dz = (zmax - zmin)/nb

            nb.times do |i|
              lvl = zmin + (i + 0.5) * dz
              color = @curve_style.color_map.z_color(lvl, zmin, zmax)
              t.context do 
                t.stroke_color = color
                contour = table.make_contour(lvl)
                t.append_points_with_gaps_to_path(*contour)
                t.stroke
              end
            end

          end
        end
        
      end
    end
  end
end
