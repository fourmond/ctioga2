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

  Version::register_svn_info('$Revision: 151 $', '$Date: 2010-06-19 23:45:20 +0200 (Sat, 19 Jun 2010) $')

  module Graphics

    module Elements

      # This class represents a 3D (or more, to be seen later) dataset
      # as markers with various parameters parametrized (color,
      # transparency, marker scale, marker type (discrete), possibly
      # stroke and fill colors ?
      class Parametric2D  < TiogaElement

        include Log
        include Dobjects

        # The Data::Dataset object that should get plotted.
        attr_accessor :dataset

        # A Styles::CurveStyle object saying how the curve should be
        # drawn.
        #
        # Some of the elements will be overridden.
        attr_accessor :curve_style

        # For convenience only.
        attr_accessor :function

        undef :location=, :location
        
        # Creates a new Curve2D object with the given _dataset_ and
        # _style_.
        def initialize(dataset, style = nil)
          @dataset = dataset
          # We build the function on a duplicate of the values ?
          @function = Function.new(@dataset.x.values.dup, 
                                   @dataset.y.values.dup)

          ## We remove NaN, as they are not very liked by Tioga...
          #
          # \todo maybe there should be a way to *split* on NaN rather
          # than to ignore them ?
          @function.strip_nan

          @curve_style = style
        end

        # Returns the LocationStyle object of the curve. Returns the
        # one from #curve_style.
        def location
          return @curve_style.location
        end

        # Returns the Types::Boundaries of this curve.
        def get_boundaries
          return Types::Boundaries.bounds(@function.x, @function.y)
        end

        # Draws the markers, if applicable.
        def draw_markers(t)
          min = @dataset.z.values.min
          max = @dataset.z.values.max
          if @curve_style.has_marker?
            @dataset.each_values do |i, x,y,*zs|
              zi = (zs[0] - min)/(max - min)
              color = [1 - zi, 0, zi] # Pretty much hardcoded here !
              @curve_style.marker.draw_markers_at(t, x, y, { 'color' => color})
            end
          else
            error { "You really should consider using markers for that kind of stuff, at least if you want to see something out" }
          end
        end
        
        ## Actually draws the curve
        def real_do(t)
          debug { "Plotting curve #{inspect}" }
          t.context do
            ## \todo allow customization of the order of drawing,
            ## using a simple user-specificable array of path,
            ## markers... and use the corresponding #draw_path or
            ## #draw_markers... Ideally, any string could be used, and
            ## warnings should be issued on missing symbols.

            draw_markers(t)
            # draw_error_bars(t) ??
          end
        end
        
      end
    end
  end
end
