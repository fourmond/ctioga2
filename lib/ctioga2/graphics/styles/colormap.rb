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

  Version::register_svn_info('$Revision$', '$Date$')

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
        attr_accessor :below, :above

        def initialize(values = [], colors = [])
          @values = values.dup
          @colors = colors.dup
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
          l = split(str, /::/)
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
          colortype = MetaBuilder::Type.get_type(:tioga_color)

          
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
          cm.above = @above
          cm.below = @below
          p cm
          return cm
        end
        
      end

    end
  end
end
