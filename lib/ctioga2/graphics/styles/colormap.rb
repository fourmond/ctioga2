# colormap.rb: a way to map values to colors
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'ctioga2/utils'
require 'ctioga2/log'

# This module contains all the classes used by ctioga
module CTioga2

  module Graphics

    module Styles


      # A mapping Z values -> color.
      #
      # It can be a simple two-point gradient, but it can also be much
      # more complex.
      #
      # Basically, a ColorMap is a series of colors with an optional Z
      # value (taken as the average of the ones around if missing) + a
      # color for above and a color for below.
      #
      # @todo For now, ColorMap relies on the intrisic tioga color
      # map, but it would be interesting to implement that "by hand"
      # for the case when a byte of resolution isn't enough (which are
      # going to be rare, I think)
      class ColorMap

        # Z values
        attr_accessor :values

        # Corresponding colors
        attr_accessor :colors

        # Colors for points of Z value below and above the limit;
        # _nil_ for no specific value, :mask for masking them out
        #
        # @todo These are currently not implemented.
        attr_accessor :below, :above

        # Whether the map follows RGB (true) or HLS (false). On by
        # default.
        #
        # It does not change anything with respect to how the colors
        # are interpreted: whatever happens, the values are RGB.
        attr_accessor :rgb

        def initialize(values = [], colors = [])
          @values = values.dup
          @colors = colors.dup

          @rgb = true
        end
        
        # Creates a ColorMap from a text specification of the kind:
        # 
        #  Red--Blue(1.0)--Green
        #  
        # The specification can optionally be surrounded by colors with ::
        # 
        #  Green::Red--Blue::Orange
        #  
        # Means that Green are for colors below, Orange for
        # above. These colors can also be "cut" or "mask", meaning
        # that the corresponding side isn't displayed.
        def self.from_text(str)
          str = str.dup
          hls = false
          re = /(natural|hls):?/i     # Not too bad ?
          if str =~ re
            str.sub!(re,'')
            hls = true
          end

          # We first try to see if it could be a color set ?
          colorsettype = Commands::CommandType.get_type('color-set')

          begin 
            set = colorsettype.string_to_type(str)
            cm = ColorMap.new([nil] * set.size, set)
            cm.rgb = ! hls
            return cm
          rescue Exception => e
            # This is not a color set
          end

          l = str.split(/::/)
          

          if l.size == 2        # This is the complex case
            if l[1] =~ /--/
              l.push('')
            else
              l.unshift('')
            end
          elsif l.size == 1
            l.push('')
            l.unshift('')
          end

          ## @todo More and more I find that this metabuilder thing is
          ## a little cumbersome, especially since I have an
          ## additional type system on top of this one.
          colortype = Commands::CommandType.get_type('color')

          
          # Now, we have three elements
          if l[0].size > 0
            if l[0] =~ /mask|cut/i
              below = :mask
            else
              below = colortype.string_to_type(l[0])
            end
          else
            below = nil
          end

          if l[2].size > 0
            if l[2] =~ /mask|cut/i
              above = :mask
            else
              above = colortype.string_to_type(l[2])
            end
          else
            above = nil
          end

          specs = l[1].split(/--/)

          values = []
          colors = []
          for s in specs
            if s =~ /([^(]+)\((.*)\)/
              values << $2.to_f
              colors << colortype.string_to_type($1)
            else
              values << nil
              colors << colortype.string_to_type(s)
            end
          end
          cm = ColorMap.new(values, colors)
          cm.above = above
          cm.below = below
          cm.rgb = ! hls
          return cm
        end


        # Prepares the 'data', 'colormap' and 'value_mask' arguments
        # to t.create_image based on the given data, and the min and
        # max Z levels
        #
        # @todo handle masking + in and out of range.
        #
        # @todo I don't think this function is named properly.
        def prepare_data_display(t, data, zmin, zmax)
          # We correct zmin and zmax
          cmap, zmin, zmax = *self.to_colormap(t, zmin, zmax)
          
          data = t.create_image_data(data.reverse_rows,
                                     'min_value' => zmin,
                                     'max_value' => zmax)
          
          return { 'data' => data,
            'colormap' => cmap
          }
        end

        # Returns a color triplet corresponding to the given z value
        #
        # @todo For now, the HSV parameter isn't honored.
        def z_color(z, zmin, zmax)
          zvs = z_values(zmin, zmax)
          
          idx = zvs.where_first_ge(z)
          if idx && idx > 0
            x = (zvs[idx] - z)/(zvs[idx] - zvs[idx-1])
            c = Utils::mix_objects(@colors[idx-1],@colors[idx], x)
            # p [c, idx, z, zmin, zmax]
            return c
          elsif idx == 0
            return @colors.first
          else
            return @colors.last
          end
        end

        # Converts to a Tioga color_map
        #
        # @todo That won't work when there are things inside/outside
        # of the map.
        def to_colormap(t, zmin, zmax)

          # OK. Now, we have correct z values. We just need to scale
          # them between z_values[0] and z_values.last, to get a [0:1]
          # interval.
          zvs = z_values(zmin, zmax)
          p_values = zvs.dup
          p_values.sub!(p_values.first)
          p_values.div!(p_values.last)
          
          dict = {
            'points' => p_values
          }
          if @rgb
            dict['Rs'] = []
            dict['Gs'] = []
            dict['Bs'] = []
            for col in @colors
              dict['Rs'] << col[0]
              dict['Gs'] << col[1]
              dict['Bs'] << col[2]
            end
          else
            dict['Hs'] = []
            dict['Ls'] = []
            dict['Ss'] = []
            for col in @colors
              col = t.rgb_to_hls(col)
              dict['Hs'] << col[0]
              dict['Ls'] << col[1]
              dict['Ss'] << col[2]
            end
          end
          return [t.create_colormap(dict), zvs.first, zvs.last]
        end


        protected

        # Returns a Dvector holding z values corresponding to each of
        # the color.
        #
        # @todo This function will be called very often and is not
        # very efficient; there should be a way to cache the results,
        # either implicitly using a realy cache or explicitly by
        # "instantiating" the colormap for given values of zmin and
        # zmax.
        #
        # @todo This function doesn't ensure that the resulting z
        # values are monotonic, which isn't quite that good.
        def z_values(zmin, zmax)
          # Real Z values.
          z_values = @values.dup
          z_values[0] ||= zmin
          z_values[-1] ||= zmax

          # Now, we replace all the nil values by the correct position
          # (the middle or both around when only one _nil_ is found,
          # 1/3 2/3 for 2 consecutive _nil_ values, and so on).
          last_value = 0
          1.upto(z_values.size-1) do |i|
            if z_values[i]
              if last_value + 1 < i
                (last_value+1).upto(i - 1) do |j|
                  frac = (j - last_value)/(i - last_value + 1.0)
                  z_values[j] = z_values[last_value] * (1 - frac) + 
                    z_values[i] * frac
                end
              end
              last_value = i
            end
          end
          return Dobjects::Dvector[*z_values]
        end

      end

    end
  end
end
