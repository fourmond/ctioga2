# -*- coding: utf-8 -*-
# plot-element.rb: collection of small wrappers used for plots
# copyright (c) 2014 by Vincent Fourmond 
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details (in the COPYING file).


require 'ctioga2/utils'
require 'ctioga2/log'

# This module contains all the classes used by ctioga
module CTioga2

  # This module contains all graphical elements of CTioga2
  module Graphics

    module Elements
      
      # This simple wrapper makes it possible to style axes (at least
      # using parents styling)
      class AxisElement < TiogaElement
        
        define_style 'axis', Styles::AxisStyle

        attr_accessor :style

        def initialize_style(loc, dec, label)
          @style = Styles::AxisStyle::new(loc, dec, label)
          update_style(@style)
        end
      end

      # This simple wrapper makes it possible to style axes (at least
      # using parents styling)
      class MapAxisElement < TiogaElement
        
        define_style 'zaxis', Styles::MapAxisStyle

        attr_accessor :style

        def initialize(parent, opts)
          setup_style(parent, opts)
          @style = get_style()
        end
      end

      # Wrapper for the title
      class TitleElement < TiogaElement

        define_style 'title', Styles::TextLabel

        attr_accessor :style

        def initialize(parent, opts)
          setup_style(parent, opts)
          @style = Styles::TextLabel.new(nil, Types::PlotLocation.new(:top))
          update_style(@style)
        end
      end

      # Wrapper for the background
      class BackgroundElement < TiogaElement
        define_style 'background', Styles::BackgroundStyle

        attr_accessor :style

        def initialize(parent, opts)
          setup_style(parent, opts)
          @style = get_style()
        end

        def draw_background(t)
          @style.draw_background(t)
        end
      end
      

    end
  end
end
