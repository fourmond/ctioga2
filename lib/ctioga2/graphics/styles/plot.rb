# plot.rb: the style of a plot object.
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

require 'ctioga2/graphics/coordinates'

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Styles

      # The style of a Elements::Subplot object.
      #
      # TODO: it should hold
      # * labels
      # * axes and edges (in a *clean* way !)
      # * ticks
      # * background (uniform fill + watermark if applicable + possibly
      #   a picture .?)
      class PlotStyle

        include Tioga::FigureConstants

        # The various sides of the plot. A hash location -> AxisStyle.
        attr_accessor :axes

        # The default location of the X axis (well, mainly, the X label)
        attr_accessor :xaxis_location

        # The default location of the Y axis (well, mainly, the Y label)
        attr_accessor :yaxis_location

        # The title of the plot
        attr_accessor :title

        # A margin to be left around the data points
        attr_accessor :plot_margin

        # Coordinate tranforms
        attr_accessor :transforms

        def initialize
          # Default style for the plots.
          @axes = {}
          @axes[:left] = AxisStyle.new(:left, 
                                       AXIS_WITH_TICKS_AND_NUMERIC_LABELS,
                                       '$y$')
          @axes[:bottom] = AxisStyle.new(:bottom, 
                                         AXIS_WITH_TICKS_AND_NUMERIC_LABELS,
                                         '$x$')

          @axes[:right] = AxisStyle.new(:right, AXIS_WITH_TICKS_ONLY)
          @axes[:top] = AxisStyle.new(:top, AXIS_WITH_TICKS_ONLY)

          @xaxis_location = :bottom
          @yaxis_location = :left

          @title = TextLabel.new
          @title.loc = :top

          @plot_margin = nil

          @transforms = CoordinateTransforms.new
        end

        # Whether to use log scale for the given axis.
        #
        # Now the question is: how should that affect user-defined
        # axes ? It should not.
        def set_log_scale(which, val)
          case which
          when :x
            @axes[:top].log = val
            @axes[:bottom].log = val
            @transforms.x_log = val
          when :y
            @axes[:left].log = val
            @axes[:right].log = val
            @transforms.y_log = val
          else
            raise "Unknown axis: #{which.inspect}"
          end
        end

        # Returns a BaseTextStyle or similar for the given
        # location. The location is of the form:
        # * 'left', 'right', 'top', 'bottom': tick labels
        # * 'xaxis', 'yaxis': the label for the side corresponding to the
        #   locations
        # * side_(tick|label) : clear enough
        # * 'title' the title of the graph.
        def label_style(location)
          if location =~ /^\s*(left|right|top|bottom)(?:_(ticks|label))?\s*$/
            loc = $1.to_sym
            if $2 == '_label'
              return @axes[loc].axis_label
            else
              return @axes[loc].tick_label_style
            end
          elsif location =~ /^\s*([xy]axis)\s*$/
            return @axes[self.send("#{$1}_location")].axis_label
          elsif location =~ /^\s*title\s*$/
            return @title
          else
            raise "Unknown label location: #{location}"
          end
        end

        # Sets the style of the given label. Sets the text as well, if
        # applicable.
        def set_label_style(which, hash, text = nil)
          style = label_style(which)
          hash = hash.merge({'text' => text}) if text
          style.set_from_hash(hash)
        end


        # Draws all axes for the plot.
        def draw_all_axes(t)
          for which, axis in @axes
            axis.draw_axis(t)
          end
          # We draw the title last
          title.draw(t)
        end

        # Draws all axes background lines for the plot.
        def draw_all_background_lines(t)
          for which, axis in @axes
            axis.draw_background_lines(t)
          end
        end


        # Returns a deep copy of _self_, with all references stripped.
        def deep_copy
          return Marshal.load(Marshal.dump(self))
        end

        # Returns the PlotStyle object of the current plot
        def self.current_plot_style(plotmaker)
          return plotmaker.root_object.current_plot.style
        end

      end

      AxisGroup = CmdGroup.new('axes-labels',
                               "Axes and labels", "Axes and labels", 40)
      
      AxisTypeCommands = []
      [:left, :right, :top, :bottom].each do |loc|
        AxisTypeCommands << 
          Cmd.new("#{loc}",nil,"--#{loc}", 
                  [
                   CmdArg.new('axis-decoration'),
                  ]) do |plotmaker, type|
          AxisStyle.axes_object(plotmaker)[loc].type = type
          # TODO: implement options !
        end
        AxisTypeCommands.last.
          describe("Sets the type of the #{loc} axis", 
                   <<"EOH", AxisGroup)
Sets the type of the #{loc} axis.
EOH
      end

      BackgroundLinesCommands = 
        Cmd.new('background-lines', nil, '--background-lines',
                [
                 CmdArg.new('text'), # TODO: change that
                 CmdArg.new('color-or-false')
                ],{
                  'style' => CmdArg.new('line-style'),
                  'width' => CmdArg.new('float')
                }) do |plotmaker, which, color, options|
        ax = AxisStyle.axes_object(plotmaker)[which.to_sym]
        if color
          style = {'color' => color}
          style.merge!(options)
          if ax.background_lines
            ax.background_lines.set_from_hash(style)
          else
            ax.background_lines = StrokeStyle.from_hash(style)
          end
        else
          ax.background_lines = false
        end
      end
      
      BackgroundLinesCommands.describe("Sets the color of the background lines", 
                                       <<"EOH", AxisGroup)
Sets the color of the background lines for the given axis.
EOH

      # A constant to be used for style of the labels:
      LabelStyleArguments = {
        'angle' => CmdArg.new('float'),
        'shift' => CmdArg.new('float'),
        'scale' => CmdArg.new('float'),
        'justification' => CmdArg.new('justification'),
        'color' => CmdArg.new('color'),
        'align' => CmdArg.new('alignment'),
      }


      XAxisLabelCommand = 
        Cmd.new('xlabel', '-x', '--xlabel', [ CmdArg.new('text') ],
                LabelStyleArguments) do |plotmaker, label, options|
        PlotStyle.current_plot_style(plotmaker).
          set_label_style('xaxis', options, label)
      end

      XAxisLabelCommand.describe("Sets the X label of the plot", 
                                 <<"EOH", AxisGroup)
Sets the X label of the current plot.
EOH

      YAxisLabelCommand = 
        Cmd.new('ylabel', '-y', '--ylabel', [ CmdArg.new('text') ],
                LabelStyleArguments) do |plotmaker, label, options|
        PlotStyle.current_plot_style(plotmaker).
          set_label_style('yaxis', options, label)
      end

      YAxisLabelCommand.describe("Sets the Y label of the plot", 
                                 <<"EOH", AxisGroup)
Sets the Y label of the current plot.
EOH

      TitleLabelCommand = 
        Cmd.new('title', '-t', '--title', [ CmdArg.new('text') ],
                LabelStyleArguments) do |plotmaker, label, options|
        PlotStyle.current_plot_style(plotmaker).
          set_label_style('title', options, label)
      end

      TitleLabelCommand.describe("Sets the title of the plot", 
                                 <<"EOH", AxisGroup)
Sets the title of the current plot.
EOH

      LabelStyleCommand = 
        Cmd.new('label-style', nil, '--label-style',
                [ CmdArg.new('text') ], 
                LabelStyleArguments) do |plotmaker, which, options|
        PlotStyle.current_plot_style(plotmaker).
          set_label_style(which, options)
      end
      
      LabelStyleCommand.describe("Sets the style of the given label", 
                                 <<"EOH", AxisGroup)
Sets the style of the given label. The label can be:
 * left, right, top or bottom for the tick labels
 * xaxis or yaxis for the corresponding axis labels
 * left_ticks or left_label for ticks or label of the left side (and so on)
 * title for the plot's title
EOH

    end
  end
end
