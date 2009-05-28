# background.rb: the style of the background of a plot.
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

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Styles

      # The style of the background of a plot. Handles:
      # * uniform background colors (fine)
      # * (text) watermark
      # * pictures (in a distant future ?)
      class BackgroundStyle < BasicStyle

        # The background color for a uniform fill. 
        attr_accessor :background_color
        
        # Creates a new AxisStyle object at the given location with
        # the given style.
        def initialize(location = nil, type = nil, label = nil)
          @background_color = nil
        end

        # Draws the background of the current plot. Fills up the
        # current frame.
        def draw_background(t)
          t.context do
            xl, yb, xr, yt = 
              t.bounds_left, t.bounds_bottom, t.bounds_right, t.bounds_top
            if @background_color
              t.fill_color = @background_color
              t.fill_frame
            end
          end
        end
        
      end


      BackgroundGroup = 
        CmdGroup.new('background',
                     "Background", <<EOD, 40)
Commands dealing with the aspect of the background of a plot (excluding
background lines, which are linked to axes).
EOD
      
      BackgroundColorCmd = 
        Cmd.new('background', nil, '--background', 
                [ CmdArg.new('color-or-false') ]) do |plotmaker, color|
        PlotStyle.current_plot_style(plotmaker).
          background.background_color = color
      end

      BackgroundColorCmd.describe("Background color for the plot", 
                                  <<"EOH", BackgroundGroup)
Sets the background color for the current (and subsequent?) plot.
EOH
    end
  end
end
