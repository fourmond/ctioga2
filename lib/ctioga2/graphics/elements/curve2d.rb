# curve2d.rb: a 2D curve
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

      # A Curve2D object represents a 2D curve, along with its style
      # and so on.
      #
      # \todo Put back various stylistic aspects that were present in
      # the old ctioga, such as:
      #
      # * transparency
      # * drawing order
      class Curve2D  < TiogaElement

        include Log
        include Dobjects

        # A Dobjects::Function holding the "real" X and Y values, for
        # the sake of manipulations.
        attr_accessor :function

        # Elements of the path, when there are more than one:
        attr_accessor :path_elements

        # The Data::Dataset object that should get plotted.
        attr_accessor :dataset

        # A Styles::CurveStyle object saying how the curve should be
        # drawn.
        attr_accessor :curve_style

        undef :location=, :location
        
        # Creates a new Curve2D object with the given _dataset_ and
        # _style_.
        def initialize(dataset, style = nil)
          @dataset = dataset
          if @dataset.size > 2
            warn { "Columns Y2 and further were ignored for set #{dataset.name}" }
          end
          # We build the function on a duplicate of the values ?
          @function = Function.new(@dataset.x.values.dup, 
                                   @dataset.y.values.dup)
          @curve_style = style

          # Preparation of the subpath elements
          if @curve_style.split_on_nan
            # This requires Tioga r601 !
            @path_elements = @function.split_on_nan(:xy)
            info { "Dividing into #{@path_elements.size} subpaths" }
          else
            @path_elements = [@function]
          end
          @function.strip_nan

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

        # Creates a path for the given curve. This should be defined
        # with care, as it will be used for instance for region
        # coloring and stroking. The function should only append to
        # the current path, not attempt to create a new path or empty
        # what was done before.
        def make_path(t)
          bnds = parent.get_el_boundaries(self)

          for func in @path_elements
            case @curve_style.path_style
            when /splines/
              for f in func.split_monotonic
                new_f = f.bound_values(*bnds.extrema)
                t.append_interpolant_to_path(new_f.make_interpolant)
              end
            else
              f = func.bound_values(*bnds.extrema)
              ## @todo this really doesn't look goo with filled paths
              ## (on the other hand, I don't see why they should ?)
              t.append_points_with_gaps_to_path(f.x, f.y,[0])
            end
          end
          
        end

        
        # Adds a closed path to the given FigureMaker object. The path
        # is closed according to the specification given as _fv_,
        # which is the same as the _y0_ attribute of a CurveFillStyle.
        #
        # It must not be _false_
        def make_closed_path(t, fv)
          y0 = fill_value_to_y(fv)
          make_path(t)
          close_path(t, y0)
        end

        # Strokes the path.
        def draw_path(t)
          if @curve_style.has_line?
            t.context do 
              @curve_style.line.set_stroke_style(t)
              make_path(t)
              t.stroke
            end
          end
        end

        # Draws the markers, if applicable.
        def draw_markers(t)
          if @curve_style.has_marker?
            xs = @function.x
            ys = @function.y
            @curve_style.marker.draw_markers_at(t, xs, ys)
          end
        end

        # A function to close the path created by make_path.
        # Overridden in the histogram code.
        def close_path(t, y0)
          t.append_point_to_path(@function.x.last, y0)
          t.append_point_to_path(@function.x.first, y0)
          t.close_path
        end

        # Returns the AxisSyle objects for the X and Y axes as an array.
        def get_axes
          return [ 
                  parent.style.get_axis_style(@curve_style.xaxis),
                  parent.style.get_axis_style(@curve_style.yaxis)
                 ]
        end

        # Draws the filled region according to the :fill_type element
        # of the style pseudo-hash. It can be:
        def draw_fill(t)
          return unless @curve_style.fill.y0
          t.context do
            # Remember: first setup_fill, then draw path, then do_fill
            @curve_style.fill.setup_fill(t)
            make_closed_path(t,@curve_style.fill.y0)
            @curve_style.fill.do_fill(t)
          end
        end

        def draw_errorbars(t)
          return unless @dataset.has_xy_errors?
          @dataset.each_values(true, true) do |*vals|
            @curve_style.error_bar.show_error_bar(t, *(vals[1..6]))
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

            draw_fill(t)
            draw_errorbars(t)
            draw_path(t)
            draw_markers(t)
          end
        end

        protected 

        # Converts the value of a fill value into a number (or nil)
        def fill_value_to_y(fv)
          return nil unless fv
          case fv
          when :bottom,:top
            bnds = parent.get_el_boundaries(self)
            return bnds.send(fv)
          end
          return fv
        end
        
      end
    end
  end
end
