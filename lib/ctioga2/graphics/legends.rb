# legends.rb: handling of legends
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'ctioga2/graphics/types'
require 'ctioga2/graphics/legends/items'
require 'ctioga2/graphics/legends/area'
require 'ctioga2/graphics/legends/storage'
require 'ctioga2/graphics/legends/provider'
require 'ctioga2/graphics/legends/multicols'

module CTioga2

  module Graphics

    # Now, various commands pertaining to legends

    LegendGroup = CmdGroup.new('legends', "Legends", <<EOD, 1)
Commands to specify legends and tweak their look.
EOD

    NextLegendCommand = 
      Cmd.new("legend",'-l',"--legend", 
              [ CmdArg.new('text') ]) do |plotmaker, legend|
      plotmaker.curve_generator.legend_provider.current_legend = legend
    end

    NextLegendCommand.describe("Sets the legend for the next dataset",
                               <<EOH, LegendGroup)
Sets the legend for the next dataset. Overridden by the @legend@ option
to the {command: plot} command.
EOH

    LegendLineCommand = 
      Cmd.new("legend-line",nil,"--legend-line", 
              [ CmdArg.new('text') ], 
              Styles::FullTextStyleOptions) do |plotmaker, legend, opts|
      l = Legends::LegendLine.new(legend, opts)
      plotmaker.root_object.current_plot.add_legend_item(l)
    end

    LegendLineCommand.describe("Adds a pure text line to the legend",
                               <<EOH, LegendGroup)
Adds a line of text unrelated to any curve to the legend.

The options controlling the aspect of the legend are documented in the 
{command: define-text-style} command.
EOH

    
    Commands::make_alias_for_option 'legend-line', 'alignment', 'align', true
    
    AutoLegendCommand = 
      Cmd.new("auto-legend",nil,"--auto-legend", 
              [ CmdArg.new('boolean') ]) do |plotmaker, value|
      plotmaker.curve_generator.legend_provider.auto_legend = value
    end

    AutoLegendCommand.describe("Automatically give legends to datasets",
                               <<EOH, LegendGroup)
When this option is in effect (off by default), all datasets get a legend, 
their 'dataset name', unless another legend is manually specified.
EOH

    LegendStyleOptions = Styles::LegendStorageStyle.options_hash()

    LegendStyleCommand = 
      Cmd.new("legend-style",nil,"--legend-style", 
              [], LegendStyleOptions) do |plotmaker, options|
      plotmaker.root_object.current_legend_area.
        legend_style.set_from_hash(options)
    end

    LegendStyleCommand.describe("Set the style of the legends",
                                <<EOH, LegendGroup)
Sets the various aspects of the style of the legends throught 
its options:
 * @dy@: the spacing between the baseline of consecutive lines;
   it is deprecated now in favor of @vpadding@;
 * @vpadding@: the space left between the bottom of a line and the top of
   the next one;
 * @scale@: the overall scale of the legends
 * @text-scale@: the scale of the text (and the markers) inside the legends

The @frame-@ options control the drawing of a frame around the legend;
they have the same meaning as corresponding ones of 
{command: define-box-style} with the @frame-@ bit dropped.
EOH

    opts = LegendStyleOptions
    opts.merge!(Elements::TiogaElement::StyleBaseOptions)
    LegendInsideCommand = 
      Cmd.new("legend-inside", nil, "--legend-inside",
              [ CmdArg.new('aligned-point')],
              opts) do |plotmaker, point, options|
      l = Legends::LegendArea.new(:inside, plotmaker.root_object.current_plot, options)
      l.legend_position = point
      plotmaker.root_object.current_plot.legend_area = l
      l.legend_style.set_from_hash(options)
    end

    LegendInsideCommand.describe("Draw legends inside the current plot",
                                 <<EOH, LegendGroup)
Using this command sets the position of the legends for the current
(sub)plot inside it, at the precise location given.

As a shortcut, {command: legend-inside} also takes all the options that 
{command: legend-style} takes, with the same effect.
EOH


    LegendMulticolOptions = Styles::MultiColumnLegendStyle.options_hash()

    LegendMultiColCommand = 
      Cmd.new("legend-multicol", nil, "--legend-multicol",
              [], LegendMulticolOptions) do |plotmaker, options|
      multicol = Legends::MultiColumnLegend.new
      multicol.style.set_from_hash(options)
      plotmaker.root_object.current_plot.
        enter_legend_subcontainer(multicol)
    end

    LegendMultiColCommand.describe("Lay out legends in several columns",
                                   <<EOH, LegendGroup)
Following legends will be layed out in multiple columns, until a call
to {command: legend-multicol-end}.
EOH

    LegendMultiColEndCommand = 
      Cmd.new("legend-multicol-end", nil, "--legend-multicol-end",
              [], {}) do |plotmaker, options|
      plotmaker.root_object.current_plot.
        enter_legend_subcontainer(nil)
    end

    LegendMultiColEndCommand.describe("End of multicolumn legends",
                                   <<EOH, LegendGroup)
Stop layout out legends in several columns
EOH


  end
end
