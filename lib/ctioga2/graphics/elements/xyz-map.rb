# parametric2d.rb: a 2D curve whose parameters depend on Z values
# copyright (c) 2006, 2007, 2008, 2009, 2010 by Vincent Fourmond

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

      # This class represents a XY map of Z values, ie something that
      # is represented using an image
      class XYZMap  < TiogaElement

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
        
        # Creates a new XYZMap object with the given _dataset_ and
        # _style_.
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
            
            dict = @curve_style.color_map.
              prepare_data_display(t,@table.table,
                                   @table.table.min,
                                   @table.table.max)

            dict.update(@table.corner_positions)
            dict.update('width' => @table.width,
                        'height' => @table.height)
            dict.update('interpolate' => false)
            if (! @curve_style.fill.transparency) || 
                (@curve_style.fill.transparency < 0.99) 
              t.show_image(dict)
            else
              info { 'Not showing map as transparency is over 0.99' }
            end
          end
        end
        
      end
    end
  end
end
