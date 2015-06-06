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

  module Graphics

    module Elements

      # A histogram
      class Histogram < Curve2D
          

        include Log
        include Dobjects

        # The histogram style at the moment of the creation of the
        # object.
        attr_accessor :histogram_style


        def initialize(dataset, style, hstyle)
          super(dataset, style)
          @histogram_style = hstyle
        end

        def get_boundaries
          ry = modified_yvalues
          bnds =  Types::Boundaries.bounds(@function.x, ry)
          if ! @within_gb
            base = get_base

            nb = bnds.dup
            nb.bottom = base
            nb.top = base

            # include the width ?
          

            bnds.extend(nb)
          end
          return bnds
        end


        # First, a very naive way.

        def make_path(t)
          base = get_base

          w, ho, yo = *get_properties(t)

          org = get_cached_organization
          h_o = org[:has_offsets][self]

          for x,y in @function
            xl = x + ho
            xr = xl + w
            b = yo[x]
            t.move_to_point(xl, base+b)
            t.append_point_to_path(xl, y+b)
            t.append_point_to_path(xr, y+b)
            t.append_point_to_path(xr, base+b)
            if h_o               # close !
              t.move_to_point(xl, base+b)
            end
          end
        end

        # The algorithms for closing the path just look ugly for
        # histograms that are offset from something. The reasoning
        # does not apply here.
        def make_closed_path(t, close_type = nil)
          org = get_cached_organization
          if org[:has_offsets][self]
            make_path(t)
          else
            super
          end
        end

        protected

        def modified_yvalues
          org = get_cached_organization
          if org[:has_offsets][self]
            vo = org[:y_offsets][self]
            vc = @function.y.dup
            vc.size.times do |i|
              vc[i] += vo[@function.x[i]]
            end
            return vc
          else
            return @function.y
          end
        end

        # The cache is setup in two bits:
        # * one fully metric-independent (i.e. that does not need the
        #   FigureMaker object)
        # * the metric cache, holding information about widths and the
        #   likes, that builds upon the first


        # This first cache is the organization of the whole
        # histograms. It is independent of the metrics.
        def get_cached_organization
          if ! parent.gp_cache.key?(:histograms)
            cache = {} 
            parent.gp_cache[:histograms] = cache


            hists = []

            x_values = Set.new

            parent.each_item do |el|
              if el.is_a?(Histogram)
                hists << el
                x_values.merge(el.function.x.to_a)
              end
            end

            cache[:list] = hists
            cache[:xvalues] = x_values

            # First, we must split the histograms in columns, based on
            # the :cumulative attribute. If positive or null, then the
            # index is that. If false, then, the next available index.
            # if negative, then the next available index, unless it exists
            # the index conversion here.
            index_cnv = {}

            columns = []
            cache[:indices] = {}
            for h in hists
              cm = h.histogram_style.cumulative
              if ! cm 
                cm = columns.size
              elsif cm < 0
                if ! index_cnv.key?(cm)
                  index_cnv[cm] = columns.size
                end
                cm = index_cnv[cm]
              end
              columns[cm] ||= []
              columns[cm] << h
              cache[:indices][h] = cm
            end
            cache[:columns] = columns

            offsets = {}
            isoff = {}
            for ar in columns
              base = {}
              for x in x_values
                base[x] = 0.0
              end
              next unless ar
              index = 0
              for h in ar
                offsets[h] = base.dup
                isoff[h] = (index > 0)
                for x,y in h.function
                  base[x] += y
                end
                index += 1
              end
            end
            cache[:y_offsets] = offsets
            cache[:has_offsets] = isoff

          end
          return parent.gp_cache[:histograms]
        end

        # Computes the number of histograms to be displayed in total
        # -- or, at least, the total number of slots.
        def compute_hist_number(x_values)
          case @histogram_style.compute_dx
          when nil, false
            return x_values.size
          when :mindx
            xv = Dvector.new(x_values.to_a.sort)
            x1 = xv[0..-2]
            x2 = xv[1..-1]
            x2.sub!(x1)
            x2.abs!
            subs = (xv.max - xv.min)/(x2.min)
            return subs.round+1
          else
            raise "Invalid compute-dx type: #{@histogram_style.compute_dx}"
          end
        end

        # Returns the cached metrics of all the histograms,
        # recomputing it in the process.
        def get_cached_metrics(t)
          if ! parent.gp_cache.key?(:histogram_metrics)
            cache = {} 
            parent.gp_cache[:histogram_metrics] = cache

            org = get_cached_organization
            cols = org[:columns]
            x_values = org[:xvalues]

            # Overall size of intra seps, in figure coordinates. Only
            # intra sep of the first element in a column counts !
            intra_sep = 0
            cols[0..-2].each do |col|
              if col && col.first.histogram_style.intra_sep
                intra_sep += col.first.histogram_style.intra_sep.to_figure(t, :x)
              end
            end

            inter_sep = if @histogram_style.gap
                          @histogram_style.gap.to_figure(t, :x)
                        elsif @histogram_style.intra_sep
                          @histogram_style.intra_sep.to_figure(t, :x)
                        else
                          0
                        end

            # OK, now we have all the values. For now, we assume more
            # or less that they are evenly spaced.
            #
            # Later, we'll have to use a conversion function for X
            # values (which means in particular that they won't be
            # positioned at the exact X value, but that's already the
            # case anyway).
            number = compute_hist_number(x_values)

            width = (x_values.max - x_values.min)/(number - 1).to_f
            if width.nan? || width == 0.0
              # Only 1 X value, we use a width of 1
              # ?? 
              width = 0.8
            end

            # Available width
            aw = width - intra_sep - inter_sep
            if aw < 0
              error { "Too much padding around the histograms leading to negative size. Try using smaller intra-sep or inter-sep. Ignoring them for now" }  
              aw = width
            end

            iw = aw/cols.size
            offset = -0.5 * (width - inter_sep)

            # @todo Add padding between the hists and around the
            # groups of histograms.
            
            for col in cols
              c = {}
              c[:width] = iw
              c[:x_offset] = offset
              offset += iw
              next unless col
              if col.first.histogram_style.intra_sep
                offset += col.first.histogram_style.intra_sep.to_figure(t, :x)
              end
              for h in col
                cache[h] = c
              end
            end
          end
          return parent.gp_cache[:histogram_metrics]
        end

        # Computes the horizontal offset and the width of the
        # histogram. Relies on a cache installed onto the parent.
        def get_properties(t)
          metrics = get_cached_metrics(t)
          s = metrics[self]
          org = get_cached_organization
          return [s[:width], s[:x_offset], org[:y_offsets][self] ]
        end

        def get_base
          ct = @curve_style.fill.close_type
          if ct
            if ! ct.horizontal?
              warning { "Cannot use fill types other than horizontal for histograms: #{ct.type}. Using default value" }
              return 0
            end
            
            @within_gb = true
            bnds = parent.get_el_boundaries(self)
            @within_gb = false

            begin 
              return ct.effective_value(bnds)
            rescue 
              return @function.y.min          # default value. Make sense ?
            end
          end

          # @todo Horizontal histograms ?? 
          return 0
        end

      end
    end
  end
end
