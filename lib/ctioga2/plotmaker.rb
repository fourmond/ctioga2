# plotmaker.rb: the main class for ctioga
# copyright (c) 2006, 2007, 2008, 2009, 2010 by Vincent Fourmond
  
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
#
# * Possibly wite 



# \todo make --xrange automatically select the range for the --math
# backend unless another range was explicitly specified.

require 'ctioga2/utils'
require 'ctioga2/log'

CTioga2::Log::init_logger

require 'shellwords'

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


# Miscellaneous
require 'ctioga2/postprocess'


## \mainpage CTioga2's code documentation.
# This module contains all the classes used by ctioga
#
#
# This holds the main page for CTioga2 code documentation. Most
# interesting classes/namespaces are:
# 
# * CTioga2::PlotMaker
# * CTioga2::Graphics
# * CTioga2::Commands
# * CTioga2::Data
#
# Have fun hacking...
#
# \section todo Various things and ideas...
#
# @li have a way to make one axis scale slave to another one (ie, for
# displays of rate constants vs potentials)
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  # This class is the core of ctioga. It parses the command-line arguments,
  # reads all necessary files and plots graphs. Most of its functionality
  # is delegated into classes.
  #
  # \todo An important point would be to provide a facility that holds
  # all the default values. To each would be assigned a given name,
  # and programs would only use something like
  # \code
  # value = Default::value('stuff')
  # \endcode
  # 
  # Setting up defaults would only be a question of using one single
  # command (with admittedly many optional arguments)
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

    # Additional preamble for LaTeX output
    attr_accessor :latex_preamble

    # What happens to generated PDF files (a PostProcess object)
    attr_accessor :postprocess

    # Whether or not to include the command-line used to produce the
    # file in the target PDF file.
    attr_accessor :mark

    # Whether intermediate files are cleaned up automatically
    # afterwards or not...
    attr_accessor :cleanup

    # The stack of CurveStyle objects that were used so far.
    attr_accessor :curve_style_stack
    

    # The first instance of PlotMaker created
    @@first_plotmaker_instance = nil

    # Returns the first created instance of PlotMaker. This sounds
    # less object-oriented, yes, but that can come in useful some
    # times.
    def self.plotmaker
      return @@first_plotmaker_instance
    end


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

      @postprocess = PostProcess.new

      # Make sure it is registered
      @@first_plotmaker_instance ||= self

      # We mark by default, as it comes dead useful.
      @mark = true

      # Remove intermediate files by default.
      @cleanup = true

      # Make curve style stack empty
      @curve_style_stack = []
    end

    # ctioga's entry point.
    def run(command_line)

      # The main catch-all around the plot:
      begin
        @command_line = command_line.dup
        if ENV.key? 'CTIOGA2_PRE'
          command_line.unshift(*Shellwords.shellwords(ENV['CTIOGA2_PRE']))
        end
        
        if ENV.key? 'CTIOGA2_POST'
          command_line.push(*Shellwords.shellwords(ENV['CTIOGA2_POST']))
        end
        
        @interpreter.run_command_line(command_line)
        
        # Now, draw the main figure
        file = draw_figure(@figure_name || "Plot-%03d", true)
      rescue SystemExit => e
        # We special-case the exit exception ;-)...
      rescue Exception => e
        debug { format_exception(e) }
        fatal { "#{e.message}" }
      end
    end

    # Flushes the current root object and starts a new one:
    def reset_graphics
      draw_figure(@figure_name || "Plot-%03d", true)

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

    # Draws the figure currently accumulated in the #root_object.  It
    # returns the path of the PDF file produced.
    #
    # If _figname_ contains a % sign, it will be interpreted as a
    # format, and ctioga will attempt to find the first numbered file
    # that does not exists.
    #
    # \todo
    # * cleanup or not ?
    def draw_figure(figname = "Plot-%03d", last = false)
      return if @root_object.empty?
      
      if figname =~ /%/
        i = 0
        prev = figname.dup
        while true
          f = figname % i
          if f == prev
            figname = f
            break
          end
          if File::exist?("#{f}.pdf")
            i += 1
          else
            figname = f
            break
          end
          prev = f
        end
      end
      
      info { "Producing figure '#{figname}'" }

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

      # Feed it
      @postprocess.process_file(file, last)
      return file
    end

    # Add *one* Data::Dataset object using the current style (that can
    # be overridden by stuff given as options) to the #root_object.
    #
    # \todo here, keep a state of the current styles:
    # * which is the color/marker/filling and so on of the curve ?
    # * are we drawing plain 2D curve, a histogram or something
    #   even more fancy ?
    # * this should be a separated class.
    #
    # \todo all curve objects should only take a Data::Dataset and a
    # style as arguments to new.
    def add_curve(dataset, options = {})
      plot = @root_object.current_plot
      curve = @curve_generator.
        curve_from_dataset(plot, dataset, options)
      plot.add_element(curve)
      @curve_style_stack << curve.curve_style
      info { "Adding curve '#{dataset.name}' to the current plot" }
    end

    # Transforms a _dataset_spec_ into one or several Data::Dataset
    # using the current backend (or any other that might be specified
    # in the options), and add them as curves to the #root_object,
    # using #add_curve
    def add_curves(dataset_spec, options = {})
      begin
        sets = @data_stack.get_datasets(dataset_spec, options)
      rescue Exception => exception
        error { "A problem occurred while processing dataset '#{dataset_spec}' using backend #{@data_stack.backend_factory.current.description.name}. Ignoring it." }
        debug { format_exception(exception) }
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
      t.autocleanup = @cleanup

      # The title field of the information is the command-line if marking
      # is on.
      if @mark
        title = "/Title (#{Utils::pdftex_quote_string(quoted_command_line)})\n"
      else
        title = ""
      end

      # We use Vincent's algorithm for major ticks when available ;-)...
      begin
        t.vincent_or_bill = true
        info { "Using Vincent's algorithm for major ticks" }
      rescue
        info { "Using Bill's algorithm for major ticks" }
      end

      
      # We now use \pdfinfo to provide information about the version
      # of ctioga2 used to produce the PDF, and the command-line if
      # applicable.
      t.tex_preamble += 
        "\n\\pdfinfo {\n#{title}/Creator(#{Utils::pdftex_quote_string("ctioga2 #{Version::version}")})\n}\n"
      return t
    end


    PlotGroup = CmdGroup.new('plots', "Plots","Plots",  0)

    PlotOptions = 
      Graphics::Styles::CurveStyleFactory::PlotCommandOptions.dup
    

    PlotOptions.merge!(Data::LoadDatasetOptions) do |key, oldval, newval| 
      raise "Duplicated option between PlotCommandOptions and LoadDatasetOptions"
    end

    PlotOptions.merge!(Graphics::CurveGenerator::PlotOptions) do |key, oldval, newval| 
      raise "Duplicated option between PlotCommandOptions and LoadDatasetOptions"
    end

    PlotCommand = 
      Cmd.new("plot",nil,"--plot", 
              [ CmdArg.new('dataset') ], 
              PlotOptions ) do |plotmaker, set, options|
      plotmaker.add_curves(set, options)
    end
    
    PlotCommand.describe("Plots the given datasets",
                         <<EOH, PlotGroup)
Use the current backend to load the given datasets onto the data stack
and plot them. It is a combination of the {command: load} and the
{command: plot-last} commands; you might want to see their
documentation.
EOH

    PlotLastOptions = 
      Graphics::Styles::CurveStyleFactory::PlotCommandOptions.dup

    PlotLastOptions['which'] = CmdArg.new('stored-dataset')
    
    PlotLastCommand = 
      Cmd.new("plot-last",'-p',"--plot-last", 
              [], PlotLastOptions) do |plotmaker, options|
      ds = plotmaker.data_stack.specified_dataset(options)
      options.delete('which')   # To avoid problems with extra options.
      plotmaker.add_curve(ds, options)
    end
    
    PlotLastCommand.describe("Plots the last dataset pushed onto the stack",
                             <<EOH, PlotGroup)
Plots the last dataset pushed onto the data stack (or the one
specified with the @which@ option), with the current style. All
aspects of the curve style (colors, markers, line styles...) can be
overridden through the use of options.
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
the command {command: preamble} with the argument:

@ \\usepackage[utf8]{inputenc}\\usepackage[T1]{fontenc}

EOD


    
    OutputSetupGroup =  
      CmdGroup.new('output-setup', 
                   "Output setup", <<EOD, 50)
Commands in this group deal with various aspects of the production of
output files:
 * output file location
 * post-processing (including automatic display)
 * cleanup...
EOD

    PageSizeCommand = 
      Cmd.new("page-size",'-r',"--page-size", 
              [ CmdArg.new('text') ], # \todo change that !
              { 'count-legend' => CmdArg.new('boolean')}
              ) do |plotmaker, size, options|
      plotmaker.root_object.set_page_size(size)
      if options.key? 'count-legend'
        plotmaker.root_object.count_legend_in_page = 
          options['count-legend']
      end
    end

    PageSizeCommand.describe('Sets the page size', 
                             <<EOH, OutputSetupGroup)
Sets the size of the output PDF file, in real units. Takes arguments in the 
form of 12cm x 3in (spaces can be omitted).
EOH

    CleanupCommand = 
      Cmd.new("clean",nil,"--clean", 
              [ CmdArg.new('boolean') ]) do |plotmaker, cleanup|
      plotmaker.cleanup = cleanup
    end


    CleanupCommand.describe('Remove intermediate files', 
                            <<EOH, OutputSetupGroup)
When this is on (the default), ctioga2 automatically cleans up
intermediate files produced by Tioga. When LaTeX fails, it can be
useful to have a closer look at them, so disable it to be able to look
into them.
EOH


    NameCommand = 
      Cmd.new("name",'-n',"--name", 
              [ CmdArg.new('text', 'figure name') ]) do |plotmaker, name|
      plotmaker.figure_name = name
    end


    NameCommand.describe('Sets the name of the figure', 
                         <<EOH, OutputSetupGroup)
Sets the name of the figure, which is also the base name for the output file.
This has nothing to do with the title of the plot, which can be set using
the command {command: title}.

If the name contains a %, it is interpreted by ctioga2 as a
printf-like format. It will attempt to find the first file that does
not exist, feeding it with increasing numbers.

The default value is now Plot-%03d, which means you'll get increasing numbers
automatically.
EOH

    OutputNowCommand = 
      Cmd.new("output-now",'-o',"--output", 
              [ CmdArg.new('text', 'figure name') ]) do |plotmaker, name|
      plotmaker.draw_figure(name)
    end

    OutputNowCommand.describe('Outputs the current state of the figure', 
                              <<EOH, OutputSetupGroup)
Writes a figure with the given name (see {command: name}) and keeps the 
current state. This can be used to create an animation.
EOH

    OutputAndResetCommand = 
      Cmd.new("output-and-reset",nil,"--output-and-reset", 
              [ ]) do |plotmaker|
      plotmaker.reset_graphics
    end

    OutputAndResetCommand.describe('Writes the current figure and starts anew', 
                                   <<EOH, OutputSetupGroup)
Writes the current figure and starts a fresh one. All non-graphical 
information are kept (curves loaded, figure names, preamble, and so on).
EOH

    OutputDirCommand = 
      Cmd.new("output-directory",'-O',"--output-directory", 
              [ CmdArg.new('text') ]) do |plotmaker, dir|
      plotmaker.output_directory = dir
    end

    OutputDirCommand.describe('Sets the output directory for produced files', 
                              <<EOH, OutputSetupGroup)
Sets the directory to which files will be plot. It defaults to the current
directory.
EOH


    # These commands belong rather to the PostProcess file, but, well,
    # they don't do much harm here anyway...
    

    ViewerCommand = 
      Cmd.new("viewer",nil,"--viewer", 
              [ CmdArg.new('text') ]) do |plotmaker, viewer|
      plotmaker.postprocess.viewer = viewer
    end

    ViewerCommand.describe('Uses the given viewer to view the produced PDF files', 
                           <<EOH, OutputSetupGroup)
Sets the command for viewing the PDF file after ctioga2 has been run.
EOH
    
    XpdfViewerCommand = 
      Cmd.new("xpdf",'-X',"--xpdf", [ ]) do |plotmaker|
      plotmaker.postprocess.viewer = "xpdf -z page"
    end

    XpdfViewerCommand.describe('Uses xpdf to view the produced PDF files', 
                              <<EOH, OutputSetupGroup)
Uses xpdf to view the PDF files produced by ctioga2.
EOH

    OpenViewerCommand = 
      Cmd.new("open",nil,"--open", [ ]) do |plotmaker|
      plotmaker.postprocess.viewer = "open"
    end
    
    OpenViewerCommand.describe('Uses open to view the produced PDF files', 
                               <<EOH, OutputSetupGroup)
Uses open (available on MacOS) to view the PDF files produced by ctioga2.
EOH

    SVGCommand = 
      Cmd.new("svg",nil,"--svg", 
              [CmdArg.new('boolean') ]) do |plotmaker,val|
      plotmaker.postprocess.svg = val
    end
    
    SVGCommand.describe('Converts produced PDF to SVG using pdf2svg', 
                        <<EOH, OutputSetupGroup)
When this feature is on, all produced PDF files are converted to SVG
using the neat pdf2svg program.
EOH

    EPSCommand = 
      Cmd.new("eps",nil,"--eps", 
              [CmdArg.new('boolean') ]) do |plotmaker,val|
      plotmaker.postprocess.eps = val
    end
    
    EPSCommand.describe('Converts produced PDF to EPS using pdftops', 
                        <<EOH, OutputSetupGroup)
When this feature is on, all produced PDF files are converted to EPS
using the pdftops program (from the xpdf tools suite).
EOH

    PNGCommand = 
      Cmd.new("png",nil,"--png", 
              [CmdArg.new('text', 'resolution') ],
              {
                'oversampling' => CmdArg.new('float'),
                'scale' => CmdArg.new('float'),
              }) do |plotmaker,res, opts|
      if res =~ /^\s*(\d+)\s*x\s*(\d+)\s*$/
        size = [$1.to_i, $2.to_i]
        plotmaker.postprocess.png_res = size
        if opts['oversampling']
          plotmaker.postprocess.png_oversampling = opts['oversampling']
        end
        scale = opts['scale'] || 1
        plotmaker.postprocess.png_scale = scale
        page_size = size.map { |n| (n/(1.0 *scale)).to_s + "bp" }.join('x')
        plotmaker.root_object.set_page_size(page_size)
      else
        raise "Invalid resolution for PNG output: #{res}"
      end
    end
    
    PNGCommand.describe('Converts produced PDF to PNG using convert', 
                        <<EOH, OutputSetupGroup)
Turns all produced PDF files into PNG images of the given resolution
using convert. This also has for effect to set the {command:
page-size} to the resolution divided by the 'scale' option in
Postscript points. By default, 2 pixels are rendered for 1 final to
produce a nicely antialiased image. Use the 'oversampling' option to
change that, in case the output looks too pixelized. This option only
affects conversion time.
EOH

    MarkCommand = 
      Cmd.new("mark",nil,"--mark", 
              [CmdArg.new('boolean') ]) do |plotmaker,val|
      plotmaker.mark = val
    end
    
    MarkCommand.describe('Fills the title of the produced PDF with the command-line', 
                         <<EOH, OutputSetupGroup)
When this feature is on (which is the default, as it comes in very
useful), the 'title' field of the PDF informations is set to the
command-line that resulted in the PDF file. Disable it if you don't
want any information to leak.

Please note that this will not log the values of the CTIOGA2_PRE and
CTIOGA2_POST variables, so you might still get a different output if
you make heavy use of those.
EOH

  end

end

