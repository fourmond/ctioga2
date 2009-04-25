# interpreter.rb: the interpreter of commands
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
require 'ctioga2/commands/commands'
require 'ctioga2/commands/help'
require 'ctioga2/commands/variables'
require 'ctioga2/commands/strings'
require 'ctioga2/commands/parsers/command-line'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  # This module contains the real core of ctioga2: a set of classes
  # that implement the concept of commands. Each command translates
  # into an action (of any kind).
  #
  # Commands can be specified using several ways: either using command-line
  # options/arguments or through a commands file.
  module Commands

    # An exception raised when a command is defined twice
    class DoubleDefinition < Exception
    end

    # An exception raised when a command is not known to the interpreter
    class UnknownCommand < Exception
    end

    # The core class interpreting all the commands and executing them.
    # It holds a hash class variable containing all the Command
    # objects defined so far.
    class Interpreter

      # All commands defined so far.
      @@commands = {}

      # All command groups defined so far.
      @@groups = []

      # Registers a given command. This is called automatically from
      # Command.new, so you should not have to do it yourself.
      def self.register_command(command)
        if(self.command(command.name))
          raise DoubleDefinition, "Command #{command} already defined"
        else
          @@commands[command.name] = command
        end
      end

      # Registers a given group. This is called automatically from
      # CommandGroup.new, so you should not have to do it yourself.
      def self.register_group(group)
        @@groups << group
      end

      # Deletes a command whose name is given
      def self.delete_command(cmd)
        @@commands.delete(cmd)
      end

      # Returns the command given by its name _cmd_, or nil if none was found.
      def self.command(cmd)
        return @@commands[cmd]
      end

      # A Variables object holding the ... variables ! (I'm sure you
      # guessed it !)
      attr_accessor :variables

      # The PlotMaker object that will receive the commands of the
      # Interpreter. 
      attr_accessor :plotmaker_target

      # The Parsers::CommandLineParser object used to... parse the command-line.
      # (surprising, isn't it ??)
      attr_reader :command_line_parser

      # The Help object used to display help
      attr_reader :help

      # The Parsers::FileParser object used to... parse files ?
      attr_reader :file_parser

      # Creates an Interpreter with _target_ as the PlotMaker target
      # object.
      #
      # As far as command-line and help is concerned, it takes a
      # snapshot of the current commands known to the system, so
      # please instantiate it last.
      #
      # TODO: probably this behavior is not really desired.
      # Easy to fix.
      def initialize(target)
        @plotmaker_target = target
        @command_line_parser = 
          Parsers::CommandLineParser.new(@@commands.values, 
                                         CTioga2::PlotMaker::PlotCommand)

        @help = Help.new(@@commands.values)
        @variables = Variables.new

        @file_parser = Parsers::FileParser.new
      end


      # Parses and run the given command-line, sending the commands to
      # the #plotmaker_target.
      def run_command_line(args)
        @command_line_parser.parse_command_line(args, self) do |arg|
          puts "Non-optional argument: #{arg.first}"
        end
      end

      # Parses and runs the given file. Sets PlotMaker#figure_name to
      # the base name of the given file if no figure name was
      # specified.
      def run_command_file(file)
        @file_parser.run_command_file(file, self)
        if ! @plotmaker_target.figure_name
          @plotmaker_target.figure_name = file.gsub(/\.[^.]+$/,'')
        end
      end

      # Parses and runs the given string.
      def run_commands(string)
        @file_parser.run_commands(string, self)
      end

      # Returns a Command object corresponding to the given _symbol_, or
      # raises an UnknownCommand exception.
      def get_command(symbol)
        if @@commands.key? symbol
          return @@commands[symbol]
        else
          raise UnknownCommand, "Unknown command: #{symbol}"
        end
      end

      # Returns the list of all know command names
      def command_names
        return @@commands.keys
      end

      # Runs _command_ with the given _arguments_ and _options_,
      # converting them as necessary. All the commands ran from this
      # interpreter should be ran from here.
      #
      # _command_ can be either a String or a Command
      #
      # Later, it could be a good idea to add a spying mechanism here.
      def run_command(command, arguments, options = nil)
        converted_args = command.convert_arguments(arguments)
        if options
          converted_options = command.convert_options(options)
        else
          converted_options = nil
        end
        command.run_command(@plotmaker_target, converted_args,
                            converted_options)
      end

      ################################################################
      # The following functions are part of the internal cuisine of
      # Interpreter. Don't use them directly unless you know what you
      # are doing.
      protected 

      # Nothing very much for now...
      


      # A group used during ctioga's early development
      DevelGroup = 
        CommandGroup.new("Commands used for ctioga development",
                         "Commands used for ctioga development",
                         -10, true)
      
      
      # A small command used for development
      PrintCommand = 
        Command.new("print", '-p', 
                              "--print", 
                              [
                               CommandArgument.new(:integer),
                               CommandArgument.new(:float),
                              ],
                              {
                                'integer' => CommandArgument.new(:integer),
                                'string' => CommandArgument.new(:string),
                              }
                              ) do |plotmaker, a1, a2, options|
        i = 1
        for a  in [a1, a2]
          puts "Printing: (arg #{i}) #{a.inspect} -- #{a.class}"
          i = i+1
        end
        p options
      end
      
      PrintCommand.describe("Test command", nil, DevelGroup)

      # A test of the string Parser
      ParseStringCommand = 
        Command.new("parse", '-P', 
                              "--parse", 
                              [
                               CommandArgument.new(:string),
                              ]) do |plotmaker, str|
        puts "String: #{str}"
        io = StringIO.new(str)
        str = InterpreterString.parse_until_unquoted(io, '', false)
        p str
        puts "Expands to: '#{str.expand_to_string(plotmaker.interpreter)}'"
      end
      
      ParseStringCommand.describe("Parse and expand a string",nil, DevelGroup)

      # Command definition
      DefineVariableCommand = 
        Command.new("define-recursive", '-D', 
                              "--define-recursive", 
                              [
                               CommandArgument.new(:string),
                               CommandArgument.new(:string),
                              ]) do |plotmaker, name, value|
        io = StringIO.new(value)
        str = InterpreterString.parse_until_unquoted(io, '', false)
        plotmaker.interpreter.variables.
          define_variable(name, str)
      end
      
      DefineVariableCommand.describe("Define a command",nil, 
                                     DevelGroup)

      # Command definition
      DumpCommandsCommand = 
        Command.new("dump-commands", nil, 
                    "--dump-commands", 
                    []) do |plotmaker|
        for cmd in plotmaker.interpreter.command_names.sort
          cmd = plotmaker.interpreter.get_command(cmd)
          puts "Command #{cmd.name}, #{cmd.arguments.size} arguments, group: #{(cmd.group && cmd.group.name) || 'none'}"
          puts " -> short: #{cmd.short_option} -- long: #{cmd.long_option}"

        end
      end
      
      DumpCommandsCommand.describe("List all known commands",nil, 
                                   DevelGroup)

    end
  end
  
  # An alias for Cmd
  Cmd = Commands::Command

  # An alias for CmdArg
  CmdArg = Commands::CommandArgument

  # An alias for CmdGroupx
  CmdGroup = Commands::CommandGroup
end

