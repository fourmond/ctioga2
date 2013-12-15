# histogram.rb: a histogram
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
require 'ctioga2/graphics/elements/curve2d'

require 'Dobjects/Function'


module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Elements

      # A histogram
      class Histogram < Curve2D
          

        include Log
        include Dobjects

        # The drawing code will have to depend both on the current
        # "histogram style" (just like the xy-parametric style) and the
        # overall number of histograms in the parent container.
        #
        # For that, one needs an iterator overall all leaf elements in
        # a container.
        
        def initialize(dataset, style)
          super(dataset, style)
        end

        def get_boundaries
          bnds =  Types::Boundaries.bounds(@function.x, @function.y)
          base = get_base()

          nb = bnds.dup
          nb.bottom = base
          nb.top = base
          bnds.extend(nb)
          return bnds
        end


        # First, a very naive way.

        def make_path(t)
          base = get_base()

          x0 = @function.x[0]
          xn = @function.x.last

          # Fixed width
          w = (xn - x0).abs/@function.size

          for x,y in @function
            xl = x - 0.5 * w
            xr = x + 0.5 * w
            t.move_to_point(xl, base)
            t.append_point_to_path(xl, y)
            t.append_point_to_path(xr, y)
            t.append_point_to_path(xr, base)
            # We close this path.
            t.move_to_point(xl, base)
          end
        end

        protected

        def get_base
          return 0              # @todo from histogram options -- or from fill-
          # until ?
        end

      end
    end
  end
end
