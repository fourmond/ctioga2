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

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

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
Sets the legend for the next dataset. Overridden by the legend= option
to the plot command.
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
EOH

    LegendInsideCommand = 
      Cmd.new("legend-inside", nil, "--legend-inside",
              [ CmdArg.new('aligned-point')]) do |plotmaker, point|
      l = Legends::LegendArea.new(:inside)
      l.legend_position = point
      plotmaker.root_object.current_plot.legend_area = l
    end

    LegendInsideCommand.describe("Draw legends inside the current plot",
                                 <<EOH, LegendGroup)
When this option is in effect, all legends for the current plot (and
possibly subplots) are drawn inside the current plot, at the specified 
position.
EOH

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

  end
end
