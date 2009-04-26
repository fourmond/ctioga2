# elements.rb: all drawable objects
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details (in the COPYING file).


require 'ctioga2/graphics/types'
require 'ctioga2/graphics/elements/element'
require 'ctioga2/graphics/elements/containers'
require 'ctioga2/graphics/elements/subplot'
require 'ctioga2/graphics/elements/curve2d'
require 'ctioga2/graphics/elements/primitive'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    # Now, various commands pertaining to various drawables

    PlotCoordinatesGroup = CmdGroup.new('coordinates',
                                        "Plot coordinates",
                                        "Plot coordinates", 2)
    PlotMarginCommand = 
      Cmd.new("margin",nil,"--margin", 
              [ CmdArg.new(:float) ]) do |plotmaker, margin|
      plotmaker.root_object.current_plot.style.plot_margin = margin
    end

    PlotMarginCommand.describe("Leaves a margin around data points",
                               <<EOH, PlotCoordinatesGroup)
Leaves a margin around the data points. Expressed in relative size of the
whole plot.
EOH


    # Various coordinate-related commands:
    CoordinateRelatedCommands = []
    [:x, :y].each do |x|
      cmd = 
        Cmd.new("#{x}range",nil,"--#{x}range", 
                [ CmdArg.new(:partial_float_range) ]) do |plotmaker, range|
        plotmaker.root_object.current_plot.
          user_boundaries.set_from_range(range, x)
      end
      cmd.describe("Sets the #{x.to_s.upcase} range",
                           <<EOH, PlotCoordinatesGroup)
Sets the range of the #{x.to_s.upcase} coordinates.
EOH
      CoordinateRelatedCommands << cmd

      cmd = 
        Cmd.new("#{x}offset",nil,"--#{x}offset", 
                [ CmdArg.new(:float) ]) do |plotmaker, val|
        plotmaker.root_object.current_plot.
          style.transforms.send("#{x}_offset=", val)
      end
      cmd.describe("Offset #{x.to_s.upcase} data",
                           <<EOH, PlotCoordinatesGroup)
Adds the given offset to all #{x.to_s.upcase} coordinates.
EOH
      CoordinateRelatedCommands << cmd

      cmd = 
        Cmd.new("#{x}scale",nil,"--#{x}scale", 
                [ CmdArg.new(:float) ]) do |plotmaker, val|
        plotmaker.root_object.current_plot.
          style.transforms.send("#{x}_scale=", val)
      end
      cmd.describe("Scale #{x.to_s.upcase} data",
                           <<EOH, PlotCoordinatesGroup)
Multiplies the #{x.to_s.upcase} coordinates by this factor.
EOH
      CoordinateRelatedCommands << cmd

      cmd = 
        Cmd.new("#{x}log",nil,"--#{x}log", 
                [ CmdArg.new(:boolean) ]) do |plotmaker, val|
        plotmaker.root_object.current_plot.
          style.send("set_log_scale", x, val)
      end
      cmd.describe("Use log scale for #{x.to_s.upcase}",
                           <<EOH, PlotCoordinatesGroup)
Uses a logarithmic scale for the #{x.to_s.upcase} axis.
EOH
      CoordinateRelatedCommands << cmd
    end
  end
end
