# curve2d.rb: a 2D curve
# copyright (c) 2006, 2007, 2008, 2009 by Vincent Fourmond

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

  Version::register_svn_info('$Revision: 928 $', '$Date: 2009-03-27 00:35:23 +0100 (Fri, 27 Mar 2009) $')

  module Graphics

    module Elements

      # A Curve2D object represents a 2D curve, along with its style and so
      # on.
      class Curve2D  < TiogaElement

        include Log
        include Dobjects

        # A Dobjects::Function holding the "real" X and Y values, for
        # the sake of manipulations.
        attr_accessor :function

        # The Data::Dataset object that should get plotted.
        attr_accessor :dataset

        # A Styles::CurveStyle object saying how the curve should be
        # drawn.
        attr_accessor :curve_style

        # Creates a new Curve2D object with the given _dataset_ and
        # _style_.
        def initialize(dataset, style = nil)
          @dataset = dataset
          if @dataset.size > 2
            warn "Columns Y2 and further were ignored for set #{dataset.name}"
          end
          # We build the function on a duplicate of the values ?
          @function = Function.new(@dataset.x.values.dup, 
                                   @dataset.y.values.dup)
          @curve_style = style
        end

        # Returns the Types::Boundaries of this curve.
        def get_boundaries
          return Types::Boundaries.bounds(@dataset.x, @dataset.y)
        end

        # Creates a path for the given curve. This should be defined
        # with care, as it will be used for instance for region
        # coloring and stroking. The function should only append to
        # the current path, not attempt to create a new path or empty
        # what was done before.
        def make_path(t)
          bnds = parent.real_boundaries
          #           if @style.interpolate
          #             for f in @function.split_monotonic
          #               new_f = f.bound_values(*bnds.to_a)
          #               t.append_interpolant_to_path(f.make_interpolant)
          #             end
          #           else
          f = @function.bound_values(*bnds.extrema)
          t.append_points_to_path(f.x, f.y)
          #          end
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

        # Draws the filled region according to the :fill_type element
        # of the style pseudo-hash. It can be:
        def draw_fill(t)
          #           y = y_value(@style.fill_type)
          #           return unless y

          #           t.fill_transparency = @style.fill_transparency || 0
          #           # Now is the tricky part. To do the actual fill, we first make a
          #           # path according to the make_path function.
          #           make_path(t)

          #           # Then we add two line segments that go from the end to the
          #           # beginning.
          #           close_path(t, y)

          #           # Now the path is ready. Just strike -- or, rather, fill !
          #           t.fill_color = @style.fill_color
          #           t.fill
        end

        def real_do(t)
          debug "Plotting curve #{inspect}"
          t.context do
            # TODO reinstate the choice of the order of drawing ???
            draw_path(t)
            draw_markers(t)
            #             # The fill is always first
            #             draw_fill(t)

            #             for op in CurveStyle::DrawingOrder[@style[:drawing_order]]
            #               self.send("draw_#{op}".to_sym, t)
            #             end
          end
        end
        
      end
    end
  end
end
