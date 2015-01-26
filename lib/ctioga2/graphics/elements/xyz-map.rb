# xyz-map.rb: a heatmap
# copyright (c) 2006, 2007, 2008, 2009, 2010, 2013, 2015 by Vincent Fourmond

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

  module Graphics

    module Elements

      # This class represents a XY map of Z values, ie something that
      # is represented using an image
      #
      # @todo There should be a way to automatically display level
      # lines, and possibly only that.
      class XYZMap  < PlotBasedElement

        include Log
        include Dobjects

        # The IndexedTable object representing the underlying data
        attr_accessor :tables


        # Creates a new XYZMap object with the given _dataset_ and
        # _style_.
        def initialize(dataset, style = nil)
          @dataset = dataset
          @curve_style = style
          prepare_data
          @boundaries = nil
        end

        # Prepares the internal storage of the data, from the @dataset
        def prepare_data
          @tables = @dataset.homogeneous_dtables
          info {
            str = ""
            for tbl in @tables
              str << " - #{tbl.x_values.min}, #{tbl.y_values.min} -> #{tbl.x_values.max}, #{tbl.y_values.max} #{tbl.width}x#{tbl.height}\n"
            end
            "There are #{@tables.size} different homogeneous submaps in #{@dataset.name}\n#{str}"
          }
          
        end
        
        protected :prepare_data

        # Returns the Types::Boundaries of this curve.
        def get_boundaries
          if @boundaries
            return @boundaries
          end
          bnds = Graphics::Types::Boundaries.bounds(@dataset.x.values,
                                                    @dataset.y.values)
          @boundaries = bnds
          return bnds
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

            zmin = @dataset.z.values.min
            zmax = @dataset.z.values.max

            for tbl in @tables
              dict = @curve_style.color_map.
                     prepare_data_display(t,tbl.table, zmin, zmax)
              if @curve_style.zaxis
                begin
                  @parent.style.get_axis_style(@curve_style.zaxis).
                    set_color_map(@curve_style.color_map, 
                                  tbl.table.min,
                                  tbl.table.max)
                rescue
                  error { "Could not set Z info to non-existent axis #{@curve_style.zaxis}" }
                end
              end

              dict.update(tbl.corner_positions)
              dict.update('width' => tbl.width,
                          'height' => tbl.height)
              dict.update('interpolate' => false)
              if (! @curve_style.fill.transparency) || 
                 (@curve_style.fill.transparency < 0.99) 
                t.show_image(dict)
                # t.stroke_rect(dict['ul'][0], dict['ul'][1], dict['lr'][0] - dict['ul'][0], dict['lr'][1] - dict['ul'][1])
              else
                info { 'Not showing map as transparency is over 0.99' }
              end
            end
          end
        end
        
      end
    end
  end
end
