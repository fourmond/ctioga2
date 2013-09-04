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

  Version::register_svn_info('$Revision$', '$Date$')

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

    # Increases verbosity
    VerboseLogging = 
      Cmd.new("verbose", '-v',  "--verbose", [ ]) do |plotmaker|
      CTioga2::Log::set_level(Logger::INFO)
    end
    
    VerboseLogging.describe("Makes ctioga2 more verbose", <<EOH, GeneralGroup)
With this on, ctioga2 outputs quite a fair amount of informative messages.
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
EOH

    # Includes a file
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
    
    
  end
end

