# subplot-commands.rb: commands for dealing with subplots
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

    # The group containing all commands linked to subplots and other
    # insets, frame margin selections...
    SubplotsGroup =  
      CmdGroup.new('subplots',
                   "Subplots and assimilated",
                   "Subplots and assimilated", 31)
    
    SetFrameMarginsCommand = 
      Cmd.new("frame-margins",nil,"--frame-margins", 
              [
               CmdArg.new('frame-margins'),
              ]) do |plotmaker, margins|
      
      plotmaker.root_object.current_plot.subframe = margins
    end

    SetFrameMarginsCommand.describe('Sets the margins of the current plot',
                                    <<EOH, SubplotsGroup)
Sets the margins for the current plot. Margins are the same things as the
position (such as specified for and inset). Using this within an inset or
more complex plots might produce unexpected results. The main use of this 
function is to control the padding around simple plots.
EOH

    PaddingCommand = 
      Cmd.new("padding",nil,"--padding", 
              [
               CmdArg.new('dimension'),
              ]) do |plotmaker, dim|
      
      Styles::PlotStyle.current_plot_style(plotmaker).padding = dim
    end

    PaddingCommand.describe('Sets the padding for the current plot',
                            <<EOH, SubplotsGroup)
When the {command: frame-margins} is set to automatic, ctioga2 leaves
that much space around the plot on the sides where there are no labels.
EOH


    InsetCommand =         
      Cmd.new("inset",nil,"--inset", 
              [
               CmdArg.new('box'),
              ]) do |plotmaker, box|
      subplot = plotmaker.root_object.subplot
      subplot.subframe = box
    end
    
    InsetCommand.describe('Begins a new inset',
                          <<EOD, SubplotsGroup)
Starts a new inset at the specified box. If no graphical commands have
been issued before this one, it starts a top-level box in a blank 
background. 

TODO: this surely could be clarified a little tiny bit.
EOD

    NextInsetCommand =         
      Cmd.new("next-inset",nil,"--next-inset", 
              [
               CmdArg.new('box'),
              ]) do |plotmaker, box|
      plotmaker.root_object.leave_subobject
      subplot = plotmaker.root_object.subplot
      subplot.subframe = box
    end
    
    NextInsetCommand.describe('Ends the previous inset and begins a new one',
                              <<EOD, SubplotsGroup)
Has the same effet as {command: end} followed by {command: inset}.
EOD

    EndCommand =         
      Cmd.new("end",nil,"--end", 
              []) do |plotmaker|
      plotmaker.root_object.leave_subobject
    end
    
    EndCommand.describe('Leaves the current subobject',
                        <<EOD, SubplotsGroup)
Leaves the current subobject.
EOD

    RescaleCommand =         
      Cmd.new("plot-scale",nil,"--plot-scale", 
              [CmdArg.new('float')], 
              {'what' => CmdArg.new('text')}) do |plotmaker, scale, options|
      what = options['what'] || 'text'
      case what
      when /text/i
        Styles::PlotStyle.current_plot_style(plotmaker).text_scale = scale
      when /lines/i
        Styles::PlotStyle.current_plot_style(plotmaker).lines_scale = scale
      when /both/i
        Styles::PlotStyle.current_plot_style(plotmaker).text_scale = scale
        Styles::PlotStyle.current_plot_style(plotmaker).lines_scale = scale
      else
        CTioga2::Log::error "Unkown 'what' option for plot-scale: #{what}"
      end
    end
    
    RescaleCommand.describe('Rescales the current (sub)plot',
                            <<EOD, SubplotsGroup)
Applies a scaling factor to the whole current subplot. Depending on
the 'what' option (default text), the scale applies to:
 * text ('text' or 'both')
 * marker size ('text' or 'both')
 * line widths ('lines' or 'both')
Scaling also applies to all elements of the plot that were added
before the call to plot-scale.
EOD

    # Options for the SetupGrid command:
    SetupGridOptions = {}
    for n in %w(left right top bottom dx dy)
      SetupGridOptions[n] = CmdArg.new('dimension')
    end

    SetupGridCommand = 
      Cmd.new('setup-grid', nil, '--setup-grid', 
              [ CmdArg.new('text') ], SetupGridOptions
              ) do |plotmaker, nup, options|
      grd = Types::GridLayout.new(nup)
      for f in %w(left right top bottom)
        if options.key? f
          grd.outer_margins[f] = options[f]
        end
      end
      grd.delta_x = options['dx'] if options['dx']
      grd.delta_y = options['dy'] if options['dy']
      Types::GridLayout.current_grid = grd
    end
    
    SetupGridCommand.describe("Setup grid for insets", 
                              <<"EOH", SubplotsGroup)
Sets up a grid of the given layout (such as 2x1). After this command,
arguments such as grid:0,1 can be used as the {type: box} argument of
{cmd: inset} and {cmd: next-inset} commands.
EOH


  end

end

