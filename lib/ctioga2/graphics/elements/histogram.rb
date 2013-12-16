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

require 'set'

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

          # include the width ?
          

          bnds.extend(nb)
          return bnds
        end


        # First, a very naive way.

        def make_path(t)
          base = get_base()

          w, o = *get_properties(t)

          for x,y in @function
            xl = x + o
            xr = xl + w
            t.move_to_point(xl, base)
            t.append_point_to_path(xl, y)
            t.append_point_to_path(xr, y)
            t.append_point_to_path(xr, base)
            # We close this path.
            t.move_to_point(xl, base)
          end
        end

        protected

        # Returns the cached metrics of all the histograms,
        # recomputing it in the process.
        def get_cached_metrics(t)
          if ! parent.gp_cache.key?(:histograms)
            cache = {} 
            parent.gp_cache[:histograms] = cache

            x_values = Set.new

            hists = []

            parent.each_item do |el|
              if el.is_a?(Histogram)
                hists << el
                x_values.merge(el.function.x.to_a)
              end
            end

            # OK, now we have all the values. For now, we assume more
            # or less that they are evenly spaced.
            #
            # Later, we'll have to use a conversion function for X
            # values (which means in particular that they won't be
            # positioned at the exact X value, but that's already the
            # case anyway).
            width = (x_values.max - x_values.min)/x_values.size

            iw = width/hists.size
            offset = -0.5 * width

            # @todo Add padding between the hists and around the
            # groups of histograms.
            
            for h in hists
              c = {}
              cache[h] ||= c
              c[:width] = iw
              c[:offset] = offset
              offset += iw
            end
          end
          return parent.gp_cache[:histograms]
        end

        # Computes the horizontal offset and the width of the
        # histogram. Relies on a cache installed onto the parent.
        def get_properties(t)
          cache = get_cached_metrics(t)
          s = cache[self]
          return [s[:width], s[:offset]]
        end

        def get_base

          # @todo Use fill, and make the difference between horizontal
          # and vertical histograms, based on the fill-until spec ?
          #
          # This in particular means that we can't mix horiz and
          # vertical histograms ?

          return 0              # @todo from histogram options -- or from fill-
          # until ?
        end

      end
    end
  end
end
