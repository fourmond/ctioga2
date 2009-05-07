# plotmaker.rb: the main class for ctioga
# copyright (c) 2006, 2007, 2008, 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).


# TODO, the main one:
# 
# It currently is a pain to make complex plots with ctioga. A real
# pain. What could be done to improve the situation ?
# 
# * hide the difference between edges and axes.
# * the layout mechanism is not comfortable enough to work with, especially
#   with the need for relative positioning.
#
# Would it be possible to allow for the 'real size' to be determined
# *afterwards* ??? Difficult !

# TODO, an even bigger one:
# Switch to a real command-based plotting program:
#  - any single operation that is realized by ctioga would be a command
#  - every single of these commands would take a given (fixed) number of
#    parameters (we should take care about boolean stuff)
#  - every command would be of course reachable as command-line options
#    but it could also be within files
#  - in these files, provide an additional mechanism for quickly defining
#    variables and do variable substitution.
#  - one command (plus arguments) per line, with provisions for
#    line-splitting
#  - allow some kind of 'include' directives (that would also be used for
#    cmdline inclusion of files)
#  - command-line arguments and command files could intermix (that *would*
#    be fun, since it would allow very little changes to a command-line
#    to change significantly the look of a file...!)
#  - LONG TERM: allow conditionals and variable
#    definition/substitution on command-line ?
#  - Use typed variables, converted into string when substitution occurs,
#    but manipulable as *typed* before ?? proposed syntax:
#    type: variable = contents ?
#
#  Each command could take *typed* arguments. That would allow typed
#  variables along with a string-to-type conversion ? (is that useful
#  ?) NO. Commands take String. And that is fine...
#
#  Provide *optional* hash-like arguments that probably could not be
#  used in the command-line, but could be in the file.
#
#  Provide self-documentation in each and every command
#
#  Manipulations of a buffer stack - including mathematical
#  expressions; provide commands to only *load* a file, but not
#  necessarily draw it.
#
#  Provide a way to 'save' a command-line into a command-file.
#
#  Write as many test suites as possible ??
#
#  Merge Metabuilder and Backends into the ctioga code base. There's
#  no need for extra complexity.
#
#  That requires a huge amount of work, but on the other hand, that
#  would be much more satisfactory than the current mess.
#
#  Commands would be part of "groups".
#
#  Release a new version of ctioga before that.
#
#  Don't rely on huge mess of things !

# IDEAS:
#
# * write a :point type that would parse figure/frame/page coordinates + maybe
#   arbitrary additions ?
# * drop the layout system, but instead write a simple plotting system:
#   - start the image as a figure
#   - start a subplot in the full figure if nothing was specified before the
#     first dataset
#   - start subplots manually using --inset or things of this spirit
#   - maybe, for the case when subplots were manually specified, resize
#     the graph so it fits ? (difficult, especially if the positions/sizes
#     are relative... but trivial if that isn't the case. Maybe provide
#     a autoresize function for that ? Or do it automatically if all the
#     toplevel (sub)plot positions are absolute ?)
#     
#   This scheme would allow for a relatively painless way to draw graphs...


# TODO: make --xrange automatically select the range for the --math
# backend unless another range was explicitly specified.

require 'ctioga2/utils'
require 'ctioga2/log'

# Maybe, maybe, maybe... We need tioga ?
require 'Tioga/FigureMaker'


# Command interpreter
require 'ctioga2/commands/interpreter'
# Various global scope commands:
require 'ctioga2/commands/general-commands'
# Introspection...
require 'ctioga2/commands/doc/introspection'
require 'ctioga2/commands/doc/documentation-commands'


# Data handling
require 'ctioga2/data/dataset'
require 'ctioga2/data/stack'
require 'ctioga2/data/backends/factory'


# Graphics
require 'ctioga2/graphics/root'
require 'ctioga2/graphics/styles'
require 'ctioga2/graphics/generator'




# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  # This class is the core of ctioga. It parses the command-line arguments,
  # reads all necessary files and plots graphs. Most of its functionality
  # is delegated into classes.
  class PlotMaker

    # Include logging facilities for ctioga2
    include CTioga2::Log

    # The Commands::Interpreter object which runs all the commands.
    attr_accessor :interpreter

    # The Data::DataStack object that manipulates Dataset objects
    attr_accessor :data_stack

    # The Graphics::RootObject in charge of holding all things that
    # will eventually get drawn
    attr_accessor :root_object

    # A Graphics::CurveGenerator object in charge of producing
    # suitable elements to be added to the Graphics::RootObject
    attr_accessor :curve_generator


    # Below are simple plot attributes. Maybe they should be in their
    # own namespace.

    # The name of the figure
    attr_accessor :figure_name

    # The output directory
    attr_accessor :output_directory

    # The viewer command. If not _nil_, automatically spawn a viewer
    # after the final figure.
    attr_accessor :viewer_command

    # Additional preamble for LaTeX output
    attr_accessor :latex_preamble


    # Setting up of the PlotMaker object
    def initialize
      CTioga2::Log::init_logger
      @data_stack = Data::DataStack.new
      @root_object = Graphics::RootObject.new
      @interpreter = Commands::Interpreter.new(self)
      @curve_generator = Graphics::CurveGenerator.new

      # Figure name:
      @figure_name = nil

      # Original preamble
      @latex_preamble = ""
    end

    # ctioga's entry point.
    def run(command_line)
      @command_line = command_line.dup
      @interpreter.run_command_line(command_line)

      # Now, draw the main figure
      file = draw_figure(@figure_name || "Plot", true)
    end

    # Flushes the current root object and starts a new one:
    def reset_graphics
      draw_figure(@figure_name || "Plot", true)

      @root_object = Graphics::RootObject.new
      @curve_generator = Graphics::CurveGenerator.new
    end
    
    # Returns a quoted version of the command line, that possibly
    # could be used again to reproduce the same results.
    def quoted_command_line
      quoted_args = @command_line.collect do |s|
        Utils::shell_quote_string(s)
      end.join ' '
      
      return "#{File.basename($0)} #{quoted_args}"
    end

    # Draws the figure currently accumulated in the #root_object.
    # It returns the path of the PDF file produced.
    #
    # TODO:
    # * handling of subdirectories
    # * other outputs (EPS, SVG, PNG)
    # * cleanup or not ?
    # * spawning of xpdf or any other viewer, for that matter.
    #   (could be forked, too, for that)
    def draw_figure(figname = "Plot", view = false)
      return if @root_object.empty?
      info "Producing figure '#{figname}'"

      t = create_figure_maker
      # If figname is clearly a path, we split it into directory/name
      # and set the output directory to directory.
      if File::basename(figname) != figname
        dir = File::dirname(figname)
        # If path is relative and output_directory is specified, we make
        # the path relative to output_dir
        if @output_directory && dir =~ /^[^\/~]/
          dir = File::join(@output_directory, dir)
        end
        t.save_dir = dir
        figname = File::basename(figname)
      elsif @output_directory
        t.save_dir = @output_directory
      end

      t.def_figure(figname) do
        @root_object.draw_root_object(t)
      end
      t.make_preview_pdf(t.figure_index(figname))

      file = t.save_dir ? File::join(t.save_dir, figname + ".pdf") : 
        figname + ".pdf"
      if view && @viewer_command
        if @viewer_command =~ /%s/
          cmd = @viewer_command % file
        else
          cmd = "#{@viewer_command} #{file}"
        end
        spawn(cmd)
      end
      return file
    end

    # Add *one* Data::Dataset object using the current style (that can
    # be overridden by stuff given as options) to the #root_object.
    #
    # TODO: here, keep a state of the current styles:
    # * which is the color/marker/filling and so on of the curve ?
    # * are we drawing plain 2D curve, a histogram or something
    #   even more fancy ?
    # * this should be a separated class.
    #
    # TODO: all curve objects should only take a Data::Dataset and a
    # style as arguments to new.
    def add_curve(dataset, options = {})
      plot = @root_object.current_plot
      curve = @curve_generator.curve_from_dataset(plot, 
                                                  dataset, options)
      plot.add_element(curve)
      info "Adding curve '#{dataset.name}' to the current plot"
    end

    # Transforms a _dataset_spec_ into one or several Data::Dataset
    # using the current backend (or any other that might be specified
    # in the options), and add them as curves to the #root_object,
    # using #add_curve
    def add_curves(dataset_spec, options = {})
      begin
        sets = @data_stack.get_datasets(dataset_spec)
      rescue Exception => exception
        error "A problem occurred while processing dataset '#{dataset_spec}' using backend #{@data_stack.backend_factory.current.description.name}. Ignoring it."
        return
      end
      for set in sets
        add_curve(set, options)
      end
    end

    protected

    # Creates a new FigureMaker object and returns it
    def create_figure_maker
      t = Tioga::FigureMaker.new
      t.tex_preamble += @latex_preamble

      return t
    end


    PlotGroup = CmdGroup.new('plots', "Plots","Plots",  0)

    PlotCommand = 
      Cmd.new("plot",nil,"--plot", 
              [ CmdArg.new('dataset') ], 
              Graphics::Styles::CurveStyleFactory::PlotCommandOptions
              ) do |plotmaker, set, options|
      plotmaker.add_curves(set, options)
    end
    
    PlotCommand.describe("Plots the given datasets",
                         <<EOH, PlotGroup)
Use the current backend to load the given datasets onto the data stack
and plot them.
EOH

    LaTeXGroup = CmdGroup.new('latex', "LaTeX",<<EOD, 30)
Commands providing control over the LaTeX output (preamble,
packages...)
EOD
    
    UsePackageCommand = 
      Cmd.new("use",nil,"--use", 
              [ CmdArg.new('text') ],
              { 'arguments' => CmdArg.new('text')}
              ) do |plotmaker, package, options|
      if options['arguments']
        plotmaker.latex_preamble << 
          "\\usepackage[#{options['arguments']}]{#{package}}\n"
      else
        plotmaker.latex_preamble << "\\usepackage{#{package}}\n"
      end
    end

    UsePackageCommand.describe('Includes a LaTeX package',
                               <<EOD, LaTeXGroup)
Adds a command to include the LaTeX package into the preamble. The 
arguments, if given, are given within [square backets].
EOD

    PreambleCommand = 
      Cmd.new("preamble",nil,"--preamble", 
              [ CmdArg.new('text') ]) do |plotmaker, txt|
      plotmaker.latex_preamble << "#{txt}\n"
    end

    PreambleCommand.describe('Adds a string to the LaTeX preamble',
                             <<EOD, LaTeXGroup)
Adds the given string to the LaTeX preamble of the output.
EOD

    Utf8Command = 
      Cmd.new("utf8",nil,"--utf8", []) do |plotmaker|
      plotmaker.latex_preamble << 
        "\\usepackage[utf8]{inputenc}\n\\usepackage[T1]{fontenc}"
    end

    Utf8Command.describe('Uses UTF-8 in strings',
                         <<EOD, LaTeXGroup)
Makes ctioga2 use UTF-8 for all text. It is exactly equivalent to
the command {command: preamble} with argument

  \\usepackage[utf8]{inputenc}\\usepackage[T1]{fontenc}

EOD


    
    PlotSetupGroup =  
      CmdGroup.new('plot-setup', 
                   "Plot setup", "Plot setup", 50)

    PageSizeCommand = 
      Cmd.new("page-size",'-r',"--page-size", 
              [ CmdArg.new('text') ], # TODO: change that !
              { 'count-legend' => CmdArg.new('boolean')}
              ) do |plotmaker, size, options|
      plotmaker.root_object.set_page_size(size)
      if options.key? 'count-legend'
        plotmaker.root_object.count_legend_in_page = 
          options['count-legend']
      end
    end

    PageSizeCommand.describe('Sets the page size', 
                             <<EOH, PlotSetupGroup)
Sets the size of the output PDF file, in real units. Takes arguments in the 
form of 12cm x 3in (spaces can be omitted).
EOH

    NameCommand = 
      Cmd.new("name",'-n',"--name", 
              [ CmdArg.new('text', 'figure name') ]) do |plotmaker, name|
      plotmaker.figure_name = name
    end


    NameCommand.describe('Sets the name of the figure', 
                         <<EOH, PlotSetupGroup)
Sets the name of the figure, which is also the base name for the output file.
This has nothing to do with the title of the plot, which can be set using
the command {command: title}.
EOH

    OutputNowCommand = 
      Cmd.new("output-now",'-o',"--output", 
              [ CmdArg.new('text', 'figure name') ]) do |plotmaker, name|
      plotmaker.draw_figure(name)
    end

    OutputNowCommand.describe('Outputs the current state of the figure', 
                              <<EOH, PlotSetupGroup)
Writes a figure with the given name (see {command: name}) and keeps the 
current state. This can be used to create an animation.
EOH

    OutputAndResetCommand = 
      Cmd.new("output-and-reset",nil,"--reset", 
              [ ]) do |plotmaker|
      plotmaker.reset_graphics
    end

    OutputAndResetCommand.describe('Writes the current figure and starts anew', 
                                   <<EOH, PlotSetupGroup)
Writes the current figure and starts a fresh one. All non-graphical 
information are kept (curves loaded, figure names, preamble, and so on).
EOH

    OutputDirCommand = 
      Cmd.new("output-directory",'-O',"--output-directory", 
              [ CmdArg.new('text') ]) do |plotmaker, dir|
      plotmaker.output_directory = dir
    end

    OutputDirCommand.describe('Sets the output directory for produced files', 
                              <<EOH, PlotSetupGroup)
Sets the directory to which files will be plot. It defaults to the current
directory.
EOH


    ViewerCommand = 
      Cmd.new("viewer",nil,"--viewer", 
              [ CmdArg.new('text') ]) do |plotmaker, viewer|
      plotmaker.viewer_command = viewer
    end

    ViewerCommand.describe('Uses the given viewer to view the produced PDF files', 
                           <<EOH, PlotSetupGroup)
Sets the command for viewing the PDF file after ctioga2 has been run.
EOH
    
    XpdfViewerCommand = 
      Cmd.new("xpdf",'-X',"--xpdf", [ ]) do |plotmaker|
      plotmaker.viewer_command = "xpdf -z page"
    end

    XpdfViewerCommand.describe('Uses xpdf to view the produced PDF files', 
                              <<EOH, PlotSetupGroup)
Uses xpdf to view the PDF files produced by ctioga2.
EOH

    OpenViewerCommand = 
      Cmd.new("open",nil,"--open", [ ]) do |plotmaker|
      plotmaker.viewer_command = "open"
    end
    
    OpenViewerCommand.describe('Uses open to view the produced PDF files', 
                               <<EOH, PlotSetupGroup)
Uses open (available on MacOS) to view the PDF files produced by ctioga2.
EOH

  end

end

