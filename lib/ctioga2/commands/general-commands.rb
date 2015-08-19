# general-commands.rb: various global scope commands
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
require 'ctioga2/commands/general-types'
require 'ctioga2/commands/parsers/file'

module CTioga2

  module Commands
 
    # General scope commands.
    GeneralGroup = 
      CmdGroup.new('general', "General commands", 
                   "General scope commands", 1000)
    

    CommandLineHelpOptions = {
      'pager' => CmdArg.new('boolean')
    }
    
    # Display help on the command-line
    CommandLineHelpCommand = 
      Cmd.new("command-line-help", 'h', 
              "--help", [ ], CommandLineHelpOptions) do |plotmaker, options|
      plotmaker.interpreter.doc.display_command_line_help(options)
      exit 
    end
    
    CommandLineHelpCommand.describe("Prints help on command-line options and exits",
                                    <<EOH, GeneralGroup)
Prints helps about short and long options available when run from the
command-line.
EOH

        # Display help on the command-line
    HelpOnCommand = 
      Cmd.new("help-on", nil, 
              "--help-on", [CmdArg.new('text') ]) do |plotmaker, cmd, options|
      plotmaker.interpreter.doc.display_help_on(cmd, options)
      exit 
    end
    
    HelpOnCommand.describe("Prints help text about the given command",
                           <<EOH, GeneralGroup)
Prints help about the given command
EOH

    # Prints the version of ctioga2 used
    PrintVersion = Cmd.new("version", '-V', "--version", []) do |plotmaker|
      puts "This is ctioga2 version #{CTioga2::Version::version}"
    end
    
    PrintVersion.describe("Prints the version", 
                          "Prints the version of ctioga in use", 
                          GeneralGroup)

    # Includes a file
    RunCommandFile = 
      Cmd.new("include", '-f', "--file", 
              [ CmdArg.new('file')], 
              {'log' => CmdArg.new('boolean') }
              ) do |plotmaker, file, opts|
      # Work around bug on windows !
      file = Utils::transcode_until_found(file)

      if opts['log']
        tg = file.sub(/(\.ct2)?$/, '-log.txt')
        Log::log_to(tg, "ctioga2 version '#{CTioga2::Version::version}' starting at #{Time.now} to process file: #{file}")
      end
      plotmaker.interpreter.run_command_file(file)
    end
    
    RunCommandFile.describe("Runs given command file", <<EOH, GeneralGroup)
Reads the file and runs commands found in them, using the ctioga language.

> ctioga2 -f my_file.ct2

If the @/log@ is on, then all messages are written to a -log.txt file
instead of to the terminal.
EOH

    # Evaluate a series of commands.
    EvalCommand =  Cmd.new("eval", '-e', "--eval", 
                           [ CmdArg.new('commands'), ]) do |plotmaker, string|
      plotmaker.interpreter.run_commands(string)
    end
    
    EvalCommand.describe("Runs the given commands", <<EOH, GeneralGroup)
Runs the given strings as commands, as if given from a command file.
EOH


    # Runs a ruby file
    RunRubyFile = 
      Cmd.new("ruby-run", nil, "--ruby-run", 
              [ CmdArg.new('file')], 
              {}
              ) do |plotmaker, file, opts|
      # Work around bug on windows !
      file = Utils::transcode_until_found(file)
      Ruby::run_file(file)
    end
    
    RunRubyFile.describe("Run as Ruby code", <<EOH, GeneralGroup)
Reads the file and runs the Ruby code found inside, a bit like
Ruby would do with the @require@ command, excepted that @ctioga2@
does not follow Ruby's file searching rules: you have to specify the
full path.
EOH

    # Evaluate a series of commands.
    SetCommand =  Cmd.new("set", nil, "--set", 
                          [ CmdArg.new('text'), 
                            CmdArg.new('text') ]) do |plotmaker, variable, value|
      plotmaker.interpreter.variables.define_variable(variable, value)
    end
    
    SetCommand.describe("Sets the value of a variable", <<EOH, GeneralGroup)
Sets the value of the variable (first argument) to the given second argument.
No parsing is done.
EOH

    # Increases verbosity
    VerboseLogging = 
      Cmd.new("verbose", '-v',  "--verbose", [ ]) do |plotmaker|
      CTioga2::Log::set_level(Logger::INFO)
    end
    
    VerboseLogging.describe("Makes ctioga2 more verbose", <<EOH, GeneralGroup)
With this on, ctioga2 outputs quite a fair amount of informative messages.
EOH

    Pause = 
      Cmd.new("pause", nil,  "--pause",
              [ CmdArg.new('boolean') ]) do |plotmaker, val|
      plotmaker.pause_on_errors = val
    end
    
    Pause.describe("Pause on errors", <<EOH, GeneralGroup)
When this is on, the program will ask for confirmation before finishing, 
when errors or warnings have been shown. This is especially useful on windows 
or other environments where the terminal shuts down as soon as ctioga2 
has finished.
EOH

    # Write debugging information.
    #
    # \todo this should be the place where a lot of customization of
    # the debug output could go - including channels or things like
    # that. To be seen later on...
    DebugLogging = 
      Cmd.new("debug", nil,  "--debug", [ ]) do |plotmaker|
      CTioga2::Log::set_level(Logger::DEBUG)
    end
    
    DebugLogging.describe("Makes ctioga2 write out debugging information", 
                          <<EOH, GeneralGroup)
With this on, ctioga2 writes a whole lot of debugging information. You
probably will not need that unless you intend to file a bug report or
to tackle a problem yourself.

Be warned that it *will* slow down very significantly the processing
of ctioga2 (up to hundreds of times slower), especially if you are not
redirecting the output to a file.
EOH

    # Prints the command-line used
    EchoCmd = 
      Cmd.new("echo", nil,  "--echo", [ ]) do |plotmaker|
      STDERR.puts "Command-line used: "
      STDERR.puts plotmaker.quoted_command_line
    end
    
    EchoCmd.describe("Prints command-line used to standard error", 
                     <<EOH, GeneralGroup)
Writes the whole command-line used to standard error, quoted in such a
way that it should be usable directly for copy/paste.
EOH

    # Writes down the list of instruction run so far
    PrintInstructionsCmd = 
      Cmd.new("print-instructions", nil,  "--print-instructions", [ ]) do |plotmaker|
      for ins in plotmaker.interpreter.instructions
        puts ins.to_s
      end
    end
    
    PrintInstructionsCmd.describe("Prints the list of all the instructions run so far", 
                     <<EOH, GeneralGroup)
Writes the list of all the instructions run so far.

This is not very helpful for now, possibly.
EOH

    
  end
end

