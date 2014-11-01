# gradient-region.rb: draw neat color gradient
# copyright (c) 2010 by Vincent Fourmond
  
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

module CTioga2

  module Graphics

    module Elements

      # A GradientRegion is an object that makes color gradient for
      # the curves. Especially useful for a great number of curves,
      # and when one doesn't want to compute...
      #
      # 
      #
      # Like Region It is a fake container in the sense that all the
      # elements are actually forwarded to the parent.
      class GradientRegion < RedirectingContainer

        undef :elements
        undef :subframe

        define_style "gradient"

        # The curves which delimit the region
        attr_accessor :curves

        # The start and end colors
        attr_accessor :start_color, :end_color

        # Creates a new empty region
        def initialize(parent, root, options)
          @parent = parent
          
          # The curves whose color we should change
          @curves = []

          @root_object = root

          @legend_area = nil

          @start_color = Tioga::ColorConstants::Red
          @end_color = Tioga::ColorConstants::Green

        end

        # Adds an element. Actually forwards it to the parent.
        def add_element(element)
          parent.add_element(element)
          if element.respond_to?(:curve_style)
            @curves << element
          end
        end

        # Sets the various things from hash.
        def set_from_hash(hash)
        end

        protected 

        # Simply sets the color of the curves.
        def real_do(t)
          nb = @curves.size
          i = 0
          for c in @curves
            c.curve_style.line.color = 
              Utils::mix_objects(@end_color,@start_color, i/(nb - 1.0))
            i += 1
          end
        end

      end
    end
  end
end
