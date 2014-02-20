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

  module Graphics

    module Styles

      # The style of a Elements::Subplot object.
      #
      # \todo it should hold
      # * labels
      # * axes and edges (in a *clean* way !)
      # * ticks
      # * background (uniform fill + watermark if applicable + possibly
      #   a picture .?)
      #
      # This class is way too complex and needs too much flexibility
      # to be handled by a subclass of BasicStyle. However, all
      # substyles should be.
      class PlotStyle

        include Tioga::FigureConstants

        include Log

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
        #
        # @todo they should be axis-specific.
        attr_accessor :transforms

        # Style of the background of the plot
        attr_accessor :background

        # Scale of the lines of the plot. The plot is wrapped in a
        # t.rescale_lines call.
        attr_accessor :lines_scale

        # Scale of the text of the plot. The plot is wrapped in a
        # t.rescale_text call.
        attr_accessor :text_scale

        # A padding around the box when automatic spacing is in auto
        # mode. A Dimension.
        attr_accessor :padding

        # Mode for auto-adjust
        attr_accessor :text_auto_adjust

        # If not nil, then the boundaries are computed from the real
        # dimensions of the plot frame, using the given number as a
        # conversion factor from the output dimensions.
        attr_accessor :frame_real_size


        @@current_index = 0

        def initialize
          # Default style for the plots.
          @axes = {}
          @axes[:left] = 
            StyleSheet.style_for(AxisStyle, 'left', :left, 
                                 AXIS_WITH_TICKS_AND_NUMERIC_LABELS,
                                 '$y$')
          @axes[:bottom] = 
            StyleSheet.style_for(AxisStyle, 'bottom', :bottom, 
                                 AXIS_WITH_TICKS_AND_NUMERIC_LABELS,
                                 '$x$')

          @axes[:right] = 
            StyleSheet.style_for(AxisStyle, 'right', :right, 
                                 AXIS_WITH_TICKS_ONLY)
          @axes[:top] = 
            StyleSheet.style_for(AxisStyle, 'top', :top, 
                                 AXIS_WITH_TICKS_ONLY)

          @xaxis_location = :bottom
          @yaxis_location = :left

          @title = 
            StyleSheet.style_for(TextLabel, 'title',
                                 nil, 
                                 Types::PlotLocation.new(:top))

          @plot_margin = nil

          @transforms = CoordinateTransforms.new

          @background = 
            StyleSheet.style_for(BackgroundStyle, 'background')

          # A padding of 6bp ? Why ?? Why not ?
          @padding = Types::Dimension.new(:bp, 6)


          
          @text_size_index = @@current_index
          @@current_index += 1

          # Automatic adjustment of text sizes...
          @text_sizes = TextSizeWatcher.new
          @text_sizes.watch("title-#{@text_size_index}")

          @text_auto_adjust = :both

        end

        # Apply (destructively) the current transformations to the
        # given dataset
        def apply_transforms!(dataset)
          @transforms.transform_2d!(dataset)
        end

        # Whether to use log scale for the given axis.
        #
        # Now the question is: how should that affect user-defined
        # axes ? It should not.
        #
        # \todo This really should move to Axis when transformations
        # are handled correctly.
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

        # Sets the axis which should be used for subsequent objects
        # (for which no axis is specified) for the given plot
        def set_default_axis(which, name)
          axis = get_axis_key(name)
          self.send("#{which}axis_location=", axis)
        end


        # Returns the AxisStyle corresponding to the named
        # axis. _name_ can be:
        # 
        # * one of the named axes (ie, by default: top, left, right,
        #   bottom). All names are stripped from spaces around, and
        #   downcased (see #clean_axis_name). Can be also user-defined
        #   axes.
        #   
        # * x(axis)?/y(axis)?, which returns the default object for the
        #   given location
        #
        # \todo Maybe x2 and y2 could be provided to signify "the side
        # which isn't the default" ?
        def get_axis_style(name)
          style = @axes[get_axis_key(name)]
          if ! style
            ## @todo Type-safe exception here
            raise "Unkown named axis: '#{name}'"
          else
            return style
          end
        end

        # Returns the key corresponding to the named axis. See
        # #get_axis_style for more information; though ultimately the
        # latter is using this function.
        def get_axis_key(name)
          if name =~ /^\s*([xy])(?:axis)?\s*$/i
            return self.send("#{$1.downcase}axis_location")
          else
            return clean_axis_name(name)
          end
        end

        def set_axis_style(name, style)
          key = get_axis_key(name)
          @axes[key] = style
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
        # _text_ is not _nil_
        def set_label_style(which, hash, text = nil)
          style = get_label_style(which)
          hash = hash.merge({'text' => text}) unless text.nil?
          if hash.key?('text') and ! style.is_a?(TextLabel)
            CTioga2::Log::warn {"Text property of label #{which} was set, but this has no meaning: tick labels can't be set this way. Did you mean to use \"#{which}_label\"" + " instead ?" }
          end
          style.set_from_hash(hash)
        end


        # Draws all axes for the plot. The _bounds_ argument is that
        # computed by Subplot#compute_boundaries; it is there to
        # ensure that the axes know whether they have their own
        # coordinate system or if they just follow what's around.
        def draw_all_axes(t, bounds)
          for which, axis in @axes
            t.context do
              begin
                axis.set_bounds_for_axis(t, bounds[which])
                axis.draw_axis(t, @text_sizes)
              rescue Exception => e
                error { "Impossible to draw axis #{which}: #{e.message}" }
                debug { "Full message: #{e.inspect}\n#{e.backtrace.join("\n")}" }
              end
            end
          end
          # We draw the title last
          title.draw(t, 'title', "title-#{@text_size_index}")
        end

        # Draws all axes background lines for the plot.
        def draw_all_background_lines(t)
          for which, axis in @axes
            axis.draw_background_lines(t)
          end
        end

        # Sets up the FigureMaker object for the plot. To be called
        # just after the outermost context call for the concerned
        # plot.
        def setup_figure_maker(t)
          if @lines_scale
            t.rescale_lines(@lines_scale)
          end
          if @text_scale
            t.rescale_text(@text_scale)
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

        # Estimate the margins of the plot whose style this object
        # controls. These margins are used when the plot margins are
        # in automatic mode.
        #
        # Returns a Types::MarginsBox
        def estimate_margins(t)
          margins = [:left, :right, :top, :bottom].map do |side|
            exts = axes_for_side(side).map do |ax|
              ax.extension(t,self)
            end
            if @title.loc.is_side?(side)
              exts << @title.label_extension(t, 'title', @title.loc) * 
                (@text_scale || 1)
            end
            Types::Dimension.new(:dy, exts.max || 0)
          end

          box = Types::MarginsBox.new(*margins)
          if @padding
            for dim in box.margins
              dim.replace_if_bigger(t, @padding)
            end
          end
          return box
        end

        # Clear all axes
        def clear_axes()
          [:left, :right, :top, :bottom].each do |loc|
            style = get_axis_style(loc)
            style.decoration = Tioga::FigureConstants::AXIS_HIDDEN
            style.axis_label.text = false
          end
        end

        # Computes the margins based on the text information.
        #
        # This is very different from the one above, since this one
        # relies on measured texts to get it right !
        def compute_margins(t, prev_margins)
          margins = estimate_margins(t)
          if @text_auto_adjust == :old
            return margins
          else
            pad = if @padding
                    @padding.to_bp(t)
                  else
                    4
                  end
            nm =  @text_sizes.update_margins(t, prev_margins, pad)

            # We include the old margins, unless we have the :measure
            # text adjust mode
            if @text_auto_adjust != :measure
              nm.expand_to!(t, margins)
            end
            return nm
          end
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

        # Returns the list of AxisStyle corresponding to the given
        # side (:top, :eft, etc...)
        def axes_for_side(side)
          ret = []
          for k,v in @axes
            ret << v if v.location.is_side?(side)
          end
          return ret
        end

      end

      AxisGroup = CmdGroup.new('axes-labels',
                               "Axes and labels", "Axes and labels", 40)


      AxisTypeCommands = []
      [:left, :right, :top, :bottom].each do |loc|
        AxisTypeCommands << 
          Cmd.new("#{loc}",nil,"--#{loc}", 
                  [
                   AxisStyleOptions['decoration'],
                  ], PartialAxisStyle) do |plotmaker, dec, opts|
          style = AxisStyle.current_axis_style(plotmaker, loc)
          style.decoration = dec

          style.set_from_hash(opts)
        end
        AxisTypeCommands.last.
          describe("Sets the type of the #{loc} axis", 
                   <<"EOH", AxisGroup)
Sets the type of the #{loc} axis.

The options have the same meaning as for {command: define-axis-style},
see that command for more information.
EOH

      end

      asco = AxisStyleOptions.dup
      asco['also-axes'] = CmdArg.new('axis')

      AxisStyleCommand = 
          Cmd.new("axis-style",nil,"--axis-style", 
                  [
                   CmdArg.new('axis'),
                  ], asco) do |plotmaker, which, opts|
        axes = [which]
        if opts['also-axes']
          axes += opts['also-axes'].split(/\s*,\s*/)
        end

        for w in axes
          begin
            style = AxisStyle.current_axis_style(plotmaker, w)
            style.set_from_hash(opts)
          rescue Exception => e
            error {"Error while setting style of axis: #{w} -- #{e}"}
          end
        end
      end
      AxisStyleCommand.
        describe("Sets the style of the given axis", 
                 <<"EOH", AxisGroup)
This command can be used to set various aspects of the style of the 
given axis, through its various options, which are documented in more details 
in the {command: define-axis-style} command -- excepted for the @ticks@ bit
which are documented in the {command: ticks} command.

If the option @also-axes@ is specified, the style is also applied to
the comma-separated list of axes it contains.

EOH

      ClearAxesCommand = 
          Cmd.new("clear-axes",nil,"--clear-axes"
                  ) do |plotmaker, opts|
        PlotStyle.current_plot_style(plotmaker).clear_axes
      end
      ClearAxesCommand.
        describe("Clear all axes",
                 <<"EOH", AxisGroup)
Removes all the axes and their associated labels
EOH

      DrawingFrameCommand = 
        Cmd.new("drawing-frame",nil,"--drawing-frame", [],
                { 'units' => CmdArg.new('text') 
                }) do |plotmaker, opts|
        style = PlotStyle.current_plot_style(plotmaker)
        style.clear_axes
        style.padding = nil
        u = opts['units'] || 'cm'
        if u =~ /([\d.]+)?\s*(cm|in|bp|pt|mm)/
          nb = $1 ? $1.to_f : 1.0
          un = $2
          style.frame_real_size = 10 * nb * 
            Types::Dimension::DimensionConversion.fetch(un)
        else
          raise 'Invalid unit'
        end
      end
      DrawingFrameCommand.
        describe("Setup a drawing frame",
                 <<"EOH", AxisGroup)
Setup a drawing frame, ie a frame in which the top-left point is at 0,0,
with X and Y values positive over the whole frame, and counted in centimeters.
EOH

      
      TicksCommand = 
          Cmd.new("ticks",nil,"--ticks", 
                  [
                   CmdArg.new('axis'),
                  ], Styles::AxisTicks.options_hash) do |plotmaker, which, opts|
        style = AxisStyle.current_axis_style(plotmaker, which)
        style.ticks.set_from_hash(opts)
      end
      TicksCommand.
        describe("Sets the ticks of the given axis", 
                 <<"EOH", AxisGroup)

This command can be used to control the location of major and minor
ticks and the text of their labels for the given axis. Options
available:

 * @format@ the format of the tick labels, using a @sprintf@-like
   syntax (see below)
 * @format-last@ the format of the last of the tick labels (useful to
   include an overall "power-of-ten" factor
 * @major@ a space or comma-separated list of the positions of the
   major (labeled) ticks
 * @minor@ same for the minor ticks
 * @label@ a comma-separated list of the tick labels (must be the same
   number of elements as that of the @major@ list). If you must
   include a comma inside, then use @||@ as a separator.

Format is a normal @sprintf@ format, with the following additional
special codes:

 * @%p@ the "common power of 10": if you divide the tick values by 10
   to the power @%p@, the smallest absolute value will be between 1
   and 10 (excluding 0 of course)
 * @%b...@ is the tick value divided by this common power of 10. You
   *must* follow this spec by a usual @sprintf@ format: @%b.3g@ would
   get you a number with 3 significant digits
EOH

      BackgroundLinesCommand = 
        Cmd.new('background-lines', nil, '--background-lines',
                [
                 CmdArg.new('axis'), 
                 CmdArg.new('color-or-false')
                ],
                StrokeStyle.options_hash().without('color')
                ) do |plotmaker, which, color, options|
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
      
      BackgroundLinesCommand.
        describe("Sets the color of the background lines", 
                 <<"EOH", AxisGroup)
Sets the color of the background lines for the given axis.
EOH


      %w{x y}.each do |axis|
        labelcmd = Cmd.new("#{axis}label", "-#{axis}", 
                            "--#{axis}label", [ CmdArg.new('text') ],
                            TextLabel.options_hash().without('text')
                           ) do |plotmaker, label, options|
          PlotStyle.current_plot_style(plotmaker).
            set_label_style("#{axis}_label", options, label)
        end
        labelcmd.describe("Sets the #{axis.upcase} label of the plot", 
                          <<"EOH", AxisGroup)
Sets the #{axis.upcase} label of the current plot.
EOH

        Commands::make_alias_for_option "#{axis}label", 'alignment', 'align', true
        
        nolabelcmd = Cmd.new("no-#{axis}label", nil, 
                             "--no-#{axis}label", []) do |plotmaker|
          PlotStyle.current_plot_style(plotmaker).
            set_label_style("#{axis}_label", {}, false)
        end
        nolabelcmd.describe("Disables #{axis.upcase} label for the plot", 
                            <<"EOH", AxisGroup)
Removes the #{axis.upcase} label for the current plot.
EOH

        daxiscmd = Cmd.new("#{axis}axis", nil,
                           "--#{axis}axis", [ CmdArg.new('axis') ],
                           {}) do |plotmaker, ax|
          PlotStyle.current_plot_style(plotmaker).
            set_default_axis(axis, ax)
        end
        daxiscmd.describe("Sets default #{axis.upcase} axis for the plot",
                          <<"EOD", AxisGroup)
Sets the default axis for the #{axis.upcase} axis for all subsequent
commands take rely on default axes (such as {command: plot}, 
{command: xrange}, {command: yrange}...).
EOD
                                 
        
      end

      TitleLabelCommand = 
        Cmd.new('title', '-t', '--title', 
                [ CmdArg.new('text') ],
                TextLabel.options_hash().without('text')
                ) do |plotmaker, label, options|
        PlotStyle.current_plot_style(plotmaker).
          set_label_style('title', options, label)
      end

      TitleLabelCommand.describe("Sets the title of the plot", 
                                 <<"EOH", AxisGroup)
Sets the title of the current plot.
EOH

      Commands::make_alias_for_option 'title', 'alignment', 'align', true

      NoTitleLabelCommand = 
        Cmd.new('no-title', nil, '--no-title', []) do |plotmaker|
        PlotStyle.current_plot_style(plotmaker).
          set_label_style('title', {}, false)
      end

      NoTitleLabelCommand.describe("Disables title for the plot", 
                                   <<"EOH", AxisGroup)
Removes the title of the current plot.
EOH

      X2Command = 
        Cmd.new('x2', nil, '--x2', []) do |plotmaker|
        plotmaker.interpreter.
          run_commands("xaxis top\naxis-style top /decoration=full")
      end

      X2Command.describe("Switches to top axis for subsequent curves", 
                                   <<"EOH", AxisGroup)
Switches to using the top axis for X axis for the subsequent curves,
and turns on full decoration for the right axis. Shortcut for:

# xaxis top
# axis-style top /decoration=full
EOH

      Y2Command = 
        Cmd.new('y2', nil, '--y2', []) do |plotmaker|
        plotmaker.interpreter.
          run_commands("yaxis right\naxis-style right /decoration=full")
      end

      Y2Command.describe("Switches to right axis for subsequent curves", 
                                   <<"EOH", AxisGroup)
Switches to using the right axis for Y axis for the subsequent curves,
and turns on full decoration for the right axis. Shortcut for:

# yaxis right
# axis-style right /decoration=full
EOH

      NewZAxisCommand = 
        Cmd.new('new-zaxis', nil, '--new-zaxis',
                [
                 CmdArg.new('text')
                ],ZAxisStyle) do |plotmaker, name, options|
        axis = Styles::MapAxisStyle.new
        PlotStyle.current_plot_style(plotmaker).
          set_axis_style(name, axis)
        axis.set_from_hash(options)
      end
      
      NewZAxisCommand.
        describe("Creates a Z axis", 
                 <<"EOH", AxisGroup)
Creates a named Z axis that can display information from Z color maps 
EOH


      LabelStyleCommand = 
        Cmd.new('label-style', nil, '--label-style',
                [ CmdArg.new('label') ], # Here: change the label too... 
                FullTextLabelOptions) do |plotmaker, which, options|
        PlotStyle.current_plot_style(plotmaker).
          set_label_style(which, options)
      end

      Commands::make_alias_for_option 'label-style', 'alignment', 'align', true
      
      LabelStyleCommand.describe("Sets the style of the given label", 
                                 <<"EOH", AxisGroup)
Sets the style of the given label (see the type {type: label} for more
information). See {command: define-text-style} for detailed information 
about the meaning of the options.

The option text permits to also set the text of the label (does not
work for ticks).

For tick labels, setting the color option also sets the color for the
lines of the corresponding axis. If you don't want that, you can 
override the color using the @stroke-color@ option of 
{command: axis-style}. This will only work with Tioga version 1.11 or 
greater.
EOH


    end
  end
end
