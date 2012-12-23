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
        #
        # @todo This should be turned into a full-scale fill style
        typed_attribute :background_color, 'color-or-false'

        # The text of the watermark, or _nil_ if there should be no
        # watermark.
        typed_attribute :watermark, 'text'

        # A MarkerStringStyle object representing the style of the
        # watermark.
        sub_style :watermark_style, MarkerStringStyle, "watermark_%s" 
        
        # Creates a new AxisStyle object at the given location with
        # the given style.
        def initialize(location = nil, type = nil, label = nil)
          @background_color = nil
          @watermark_style = MarkerStringStyle.new
          @watermark_style.color = [0.5,0.5,0.5]
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
            draw_watermark(t)
          end
        end

        def draw_watermark(t)
          if @watermark
            x = t.convert_frame_to_figure_x(0.5)
            y = t.convert_frame_to_figure_y(0.5)
            
            delta_y = t.default_text_height_dy * @watermark_style.
              real_vertical_scale
            
            # We split lines on \\, just like in standard LaTeX
            lines = @watermark.split(/\s*\\\\\s*/)
            i = + (lines.size-1)/2.0
            for text in lines 
              @watermark_style.
                draw_string_marker(t, text, x, y + delta_y * i)
              i -= 1
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

      WatermarkCmd = 
        Cmd.new('watermark', nil, '--watermark', 
                [ CmdArg.new('text') ], 
                MarkerStringStyle.options_hash) do |plotmaker, text, opts|
        bg = PlotStyle.current_plot_style(plotmaker).
          background
        bg.watermark = text
        bg.watermark_style.set_from_hash(opts)
      end

      WatermarkCmd.describe("Sets a watermark for the current plot", 
                            <<"EOH", BackgroundGroup)
Sets a watermark for the background of the current plot.
EOH
    end
  end
end
