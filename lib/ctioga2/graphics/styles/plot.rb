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

        # Style of the background of the plot
        attr_accessor :background

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

          @background = BackgroundStyle.new
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

        # Returns the AxisStyle corresponding to the named
        # axis. _name_ can be:
        # * one of the named elements of axes (ie, by default: top,
        #   left, right, bottom). All names are stripped from spaces
        #   around, and downcased (see #clean_axis_name).
        # * x(axis)?/y(axis)?, which returns the default object for the
        #   given location
        def get_axis_style(name)
          if name =~ /^\s*([xy])(?:axis)?\s*$/i
            return @axes[self.send("#{$1.downcase}axis_location")]
          else
            style = @axes[clean_axis_name(name)]
            if ! style
              raise "Unkown named axis: '#{name}'"
            else
              return style
            end
          end 
        end

        # Returns a BaseTextStyle or similar for the given
        # location. The location is of the form:
        #   axis_name(_(ticks?|label))
        # or
        #   title
        #
        # If neither label nor ticks is specified in the first form,
        # ticks are implied.
        def get_label_style(location)
          if location =~ /^\s*title\s*$/
            return @title
          end
          location =~ /^\s*(.*?)(?:_(ticks?|label))?\s*$/i
          which = $2
          axis = get_axis_style($1)
          if which =~ /label/
            return axis.axis_label
          else
            return axis.tick_label_style
          end
        end

        # Sets the style of the given label. Sets the text as well, if
        # applicable.
        def set_label_style(which, hash, text = nil)
          style = get_label_style(which)
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

        protected

        # Takes a string and returns a Symbol suitable for use with
        # the #axes hash (lower case without spaces).
        def clean_axis_name(name)
          if name.is_a?(::Symbol) # Argh ! Tioga redefined Symbol !
            return name
          end
          name =~ /^\s*(.*?)\s*$/
          return $1.downcase.to_sym
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
                  ], PartialAxisStyle) do |plotmaker, dec, opts|
          style = AxisStyle.current_axis_style(plotmaker, loc)
          style.decoration = dec

          style.set_from_hash(opts)
        end
        AxisTypeCommands.last.
          describe("Sets the type of the #{loc} axis", 
                   <<"EOH", AxisGroup)
Sets the type of the #{loc} axis.
EOH
      end

      AxisStyleCommand = 
          Cmd.new("axis-style",nil,"--axis-style", 
                  [
                   CmdArg.new('axis'),
                  ], FullAxisStyle) do |plotmaker, which, opts|
        style = AxisStyle.current_axis_style(plotmaker, which)
        style.set_from_hash(opts)
      end
      AxisStyleCommand.
        describe("Sets the style of the given axis", 
                 <<"EOH", AxisGroup)
This command can be used to set various aspects of the style of the 
given axis, through its various options:
 * decoration
EOH

      BackgroundLinesCommands = 
        Cmd.new('background-lines', nil, '--background-lines',
                [
                 CmdArg.new('axis'), 
                 CmdArg.new('color-or-false')
                ],{
                  'style' => CmdArg.new('line-style'),
                  'width' => CmdArg.new('float')
                }) do |plotmaker, which, color, options|
        axis = AxisStyle.current_axis_style(plotmaker, which)
        if color
          style = {'color' => color}
          style.merge!(options)
          if axis.background_lines
            axis.background_lines.set_from_hash(style)
          else
            axis.background_lines = StrokeStyle.from_hash(style)
          end
        else
          axis.background_lines = false
        end
      end
      
      BackgroundLinesCommands.
        describe("Sets the color of the background lines", 
                 <<"EOH", AxisGroup)
Sets the color of the background lines for the given axis.
EOH


      XAxisLabelCommand = 
        Cmd.new('xlabel', '-x', '--xlabel', [ CmdArg.new('text') ],
                FullTextStyleOptions) do |plotmaker, label, options|
        PlotStyle.current_plot_style(plotmaker).
          set_label_style('x_label', options, label)
      end

      XAxisLabelCommand.describe("Sets the X label of the plot", 
                                 <<"EOH", AxisGroup)
Sets the X label of the current plot.
EOH

      YAxisLabelCommand = 
        Cmd.new('ylabel', '-y', '--ylabel', [ CmdArg.new('text') ],
                FullTextStyleOptions) do |plotmaker, label, options|
        PlotStyle.current_plot_style(plotmaker).
          set_label_style('y_label', options, label)
      end

      YAxisLabelCommand.describe("Sets the Y label of the plot", 
                                 <<"EOH", AxisGroup)
Sets the Y label of the current plot.
EOH

      TitleLabelCommand = 
        Cmd.new('title', '-t', '--title', [ CmdArg.new('text') ],
                FullTextStyleOptions) do |plotmaker, label, options|
        PlotStyle.current_plot_style(plotmaker).
          set_label_style('title', options, label)
      end

      TitleLabelCommand.describe("Sets the title of the plot", 
                                 <<"EOH", AxisGroup)
Sets the title of the current plot.
EOH

      LabelStyleCommand = 
        Cmd.new('label-style', nil, '--label-style',
                [ CmdArg.new('label') ], # Here: change the label too... 
                FullTextLabelOptions) do |plotmaker, which, options|
        PlotStyle.current_plot_style(plotmaker).
          set_label_style(which, options)
      end
      
      LabelStyleCommand.describe("Sets the style of the given label", 
                                 <<"EOH", AxisGroup)
Sets the style of the given label (see the type {type: label} for more
information).

The option text permits to also set the text of the label (does not
work for ticks). Due to a limitation in tioga, the color option does
not work for ticks either.
EOH

    end
  end
end
