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

      # This class represents a 3D (or more, to be seen later) dataset
      # as markers with various parameters parametrized (color,
      # transparency, marker scale, marker type (discrete), possibly
      # stroke and fill colors ?
      #
      # @todo What would be interesting here would be to have indexed
      # plots, ie draw one curve for each value of Z, with a color
      # indexed by Z.
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

        # For convenience only: xy functions
        attr_accessor :function

        # A hash Z value -> corresponding XY functions.
        attr_accessor :planes



        undef :location=, :location
        
        # Creates a new Curve2D object with the given _dataset_ and
        # _style_.
        def initialize(dataset, style = nil)
          @dataset = dataset
          @curve_style = style
          prepare_data
        end

        # Prepares the internal storage of the data, from the @dataset
        def prepare_data
          @function = Function.new(@dataset.x.values.dup, 
                                   @dataset.y.values.dup)
          @planes = {}
          @dataset.each_values do |i, x,y,*zs|
            @planes[zs[0]] ||= Function.new(Dvector.new, Dvector.new)
            @planes[zs[0]].x << x
            @planes[zs[0]].y << y
          end
        end
        
        protected :prepare_data

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
        def draw_path(t)
          min = @dataset.z.values.min
          max = @dataset.z.values.max
          if @curve_style.has_line?
            # We use a default color map for the lines
            @curve_style.color_map ||= 
              Styles::ColorMap.from_text("Red--Green")
            cmap = @curve_style.color_map

            for zs in @planes.keys.sort ## \todo have the sort
                                        ## direction configurable.
              f = @planes[zs]
              color = cmap.z_color(zs, min, max)
              t.context do 
                @curve_style.line.set_stroke_style(t)
                t.stroke_color = color
                t.show_polyline(f.x, f.y)
              end
            end
          end
        end


        # Draws the markers, if applicable.
        def draw_markers(t)
          min = @dataset.z.values.min
          max = @dataset.z.values.max
          if @curve_style.has_marker?
            # We use a default color map for the markers
            @curve_style.marker_color_map ||= 
              Styles::ColorMap.from_text("Red--Green")
            cmap = @curve_style.marker_color_map
            for zs in @planes.keys.sort ## \todo have the sort
                                        ## direction configurable.
              f = @planes[zs]
              color = cmap.z_color(zs, min, max)
              @curve_style.marker.draw_markers_at(t, f.x, f.y, 
                                                  { 'color' => color})
            end
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

            # draw_fill(t)
            # draw_errorbars(t)
            draw_path(t)
            draw_markers(t)
            # draw_error_bars(t) ??
          end
        end
        
      end
    end
  end
end
