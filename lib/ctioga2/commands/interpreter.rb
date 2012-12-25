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
require 'ctioga2/commands/context'
require 'ctioga2/commands/variables'
require 'ctioga2/commands/strings'
require 'ctioga2/commands/parsers/command-line'
require 'ctioga2/commands/doc/doc'

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

    # An exception raised upon invalid names.
    class InvalidName < Exception
    end

    # An exception raised when a CommandType is not known
    class InvalidType < Exception
    end

    # A CommandGroup#id or Command#name should match this regular
    # expression.
    NameValidationRE = /^[a-z0-9-]+$/

    # The core class interpreting all the commands and executing them.
    # It holds a hash class variable containing all the Command
    # objects defined so far.
    class Interpreter

      # All commands defined so far.
      @@commands = {}

      # All command groups defined so far.
      @@groups = {}

      # All types defined so fat
      @@types = {}



      # Registers a given command. This is called automatically from
      # Command.new, so you should not have to do it yourself.
      def self.register_command(command)
        if self.command(command.name)
          raise DoubleDefinition, "Command '#{command.name}' already defined"
        else
          if command.name =~ NameValidationRE
            @@commands[command.name] = command
          else
            raise InvalidName, "Name '#{command.name}' is invalid"
          end
        end
      end

      # Registers a given group. This is called automatically from
      # CommandGroup.new, so you should not have to do it yourself.
      def self.register_group(group)
        if self.group(group.id)
          raise DoubleDefinition, "Group '#{group.id}' already defined"
        else
          if group.id =~ NameValidationRE
            @@groups[group.id] = group
          else
            raise InvalidName, "Name '#{group.id}' is invalid"
          end
        end
      end

      # Registers a given type. This is called automatically from
      # CommandType.new, so you should not have to do it yourself.
      def self.register_type(type)
        if self.type(type.name)
          raise DoubleDefinition, "Type '#{type.name}' already defined"
        else
          if type.name =~ NameValidationRE
            @@types[type.name] = type
          else
            raise InvalidName, "Name '#{type.name}' is invalid"
          end
        end
      end


      # Returns the named CommandType
      def self.type(name)
        return @@types[name]
      end

      # Returns all registered CommandType objects
      def self.types
        return @@types
      end

      # Deletes a command whose name is given
      def self.delete_command(cmd)
        @@commands.delete(cmd)
      end

      # Returns the command given by its name _cmd_, or nil if none was found.
      def self.command(cmd)
        return @@commands[cmd]
      end

      # Returns the groups given by its _id_, or nil if none was found.
      def self.group(id)
        return @@groups[id]
      end

      # Returns the commands hash
      def self.commands
        return @@commands
      end

      # Returns the groups hash
      def self.groups
        return @@groups
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

      # The Documentation::Doc object that can interact with documentation
      attr_reader :doc

      # The Parsers::FileParser object used to... parse files ?
      attr_reader :file_parser

      # The current context
      attr_accessor :context

      # Creates an Interpreter with _target_ as the PlotMaker target
      # object.
      #
      # As far as command-line and help is concerned, it takes a
      # snapshot of the current commands known to the system, so
      # please instantiate it last.
      #
      # \todo probably this behavior is not really desired.
      # Easy to fix.
      def initialize(target)
        @plotmaker_target = target
        @command_line_parser = 
          Parsers::CommandLineParser.new(@@commands.values, 
                                         CTioga2::PlotMaker::PlotCommand)

        @doc = Documentation::Doc.new()
        @variables = Variables.new

        # We import the variables from the environment, just like a in
        # a Makefile
        for k, v in ENV
          @variables.define_variable(k, v)
        end

        @file_parser = Parsers::FileParser.new
        @context = ParsingContext.new
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
        if ! @plotmaker_target.figure_name
          @plotmaker_target.figure_name = file.gsub(/\.[^.]+$/,'')
        end
        @file_parser.run_command_file(file, self)
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
    end

    def self.make_alias_for_option(cmd_name, option, 
                                   new_name, deprecated = false)
      cmd = Interpreter.command(cmd_name)
      if ! cmd
        raise "Impossible to find command #{cmd_name}"
      end
      new_opt = cmd.optional_arguments[option]
      if ! new_opt
        raise "No #{option} option to command #{cmd_name}"
      end
      new_opt = new_opt.dup
      new_opt.option_deprecated = deprecated
      new_opt.option_target = option
      cmd.optional_arguments[new_name] = new_opt
    end
  end
  
  # An alias for Commands::Command
  Cmd = Commands::Command

  # An alias for Commands::CommandArgument
  CmdArg = Commands::CommandArgument

  # An alias for Commands::CommandGroup
  CmdGroup = Commands::CommandGroup

  # An alias for Commands::CommandType
  CmdType = Commands::CommandType
end

