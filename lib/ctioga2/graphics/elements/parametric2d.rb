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

  module Graphics

    module Elements

      # This class represents a 3D (or more, to be seen later) dataset
      # as markers with various parameters parametrized (color,
      # transparency, marker scale, marker type (discrete), possibly
      # stroke and fill colors ?
      #
      # @todo Find a mechanism to really say what varies. Ideally, one
      # would want to say:
      # * Y2 is marker color
      # * Y3 is marker size
      # * Y4 only takes discrete values and represents markers
      # 
      # However, this is complex enough to be left out of the curve
      # factory, I think. Color maps can be used for colors, but for
      # the rest, things will have to be implemented as parameters to
      # the curve generator, or even separated commands.
      class Parametric2D  < PlotBasedElement

        include Log
        include Dobjects

        # For convenience only: xy functions
        attr_accessor :function

        # A hash Z value -> corresponding XY functions.
        attr_accessor :planes

        # A ParametricPlotStyle object handling the correspondance
        # between Z axis and stylistic aspects
        attr_accessor :parametric_style

        # Creates a new Curve2D object with the given _dataset_ and
        # _style_.
        def initialize(dataset, style = nil, parametric_plot_style = nil)
          @dataset = dataset
          @curve_style = style
          
          @parametric_style = parametric_plot_style
          prepare_data
        end

        # Prepares the internal storage of the data, from the @dataset
        def prepare_data
          @function = Function.new(@dataset.x.values.dup, 
                                   @dataset.y.values.dup)

          ## @todo this should eventually use Dataset::index_on_cols.
          @planes = {}
          @dataset.each_values do |i, x,y,*zs|
            @planes[zs[0]] ||= Function.new(Dvector.new, Dvector.new)
            @planes[zs[0]].x << x
            @planes[zs[0]].y << y
          end

          
          @zmin = []
          @zmax = []

          ## @todo This should rather use Z axes in the end ?
          (@dataset.ys.size - 1).times do |i|
            @zmin << @dataset.ys[i+1].values.min
            @zmax << @dataset.ys[i+1].values.max
          end
        end
        
        protected :prepare_data

        # Returns the Types::Boundaries of this curve.
        def get_boundaries
          return Types::Boundaries.bounds(@function.x, @function.y)
        end

        # Draws the path lines, if applicable.
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
          if @curve_style.has_marker?
            # We use a default color map for the markers
            @curve_style.marker_color_map ||= 
              Styles::ColorMap.from_text("Red--Green")

            @dataset.each_values do |i,x,y,*z|
              ms = @parametric_style.marker_style(@curve_style, 
                                                  z, @zmin, @zmax)
              ms.draw_markers_at(t, x, y)
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

            @parametric_style.prepare
            if @dataset.z_columns < @parametric_style.z_columns_needed
              error { "Need #{@parametric_style.z_columns_needed} Z columns, but have only #{@dataset.z_columns} for dataset #{@dataset.name}" }
              return
            end
              
            draw_path(t)
            draw_markers(t)

            if @curve_style.zaxis
              begin
                @parent.style.get_axis_style(@curve_style.zaxis).
                  set_color_map(@curve_style.marker_color_map, 
                                @dataset.z.values.min,
                                @dataset.z.values.max)
              rescue
                error { "Could not set Z info to non-existent axis #{@curve_style.zaxis}" }
              end
            end

            # draw_error_bars(t) ??
          end
        end
        
      end
    end
  end
end
