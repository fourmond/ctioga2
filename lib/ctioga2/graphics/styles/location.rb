# drawable.rb: style objects pertaining to drawable objects.
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

    # All the styles
    module Styles

      # This class represents various aspects of the location of a
      # object within a plot, such as:
      # 
      # * X and Y axes
      # * foreground/normal/background position
      # * whether it should be clipped or not.
      #
      # \todo currently only X and Y axes are implemented.
      class LocationStyle < BasicStyle
        
        # The name of the X axis, something to be fed to
        # PlotStyle#get_axis_key
        typed_attribute :xaxis, 'axis'

        # The name of the Y axis
        typed_attribute :yaxis, 'axis'

        # Given a PlotStyle object, returns the axes keys as would
        # PlotStyle#get_axis_key
        def get_axis_keys(plot_style)
          return [
                  plot_style.get_axis_key(@xaxis || 'x'),
                  plot_style.get_axis_key(@yaxis || 'y')
                 ]
        end

        # Finalizes the location of the object, that is (for now)
        # resolves references to default axes.
        def finalize!(plot_style)
          @xaxis, @yaxis = *get_axis_keys(plot_style)
        end
        
      end

    end
  end
end

