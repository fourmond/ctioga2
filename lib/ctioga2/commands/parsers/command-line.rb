# command-line.rb: a command-line parser for ctioga2
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
require 'ctioga2/commands/commands'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    # In this modules are classes that parse a source of commands, and
    # yield to the caller the commands (Command) along with their
    # unprocessed arguments.
    module Parsers

      # An exception raised upon redefinition of a short or long
      # option.
      class OptionRedefined < Exception
      end

      # An exception raised when the parser encounters an unkown
      # option.
      class OptionUnkown < Exception
      end

      # This class is in charge of parsing a command-line against a
      # list of known commands.
      class CommandLineParser
        include Log

        # A hash 'short-option-letter' => [number of args, Command]
        attr_reader :short_options

        # A hash 'long-option-name'    => [number of args, Command]
        attr_reader :long_options

        # The list of commands
        attr_reader :commands

        # A [number of args, Command] for the default command, ie
        # the one that applies on non-command files.
        attr_reader :default_command
        
        # Creates a CommandLineParser that will understand the
        # given _commands_
        def initialize(commands, default = nil)
          @commands = commands
          prepare_option_hashes(default)
        end


        # Takes an _argv_ array representing the command-line and a
        # target _intepreter_, and runs the commands found on the
        # command line. Yields arguments which are not part of a
        # command, or feed them to the #default_command if it was
        # specified.
        def parse_command_line(argv, interpreter)
          # We duplicate the original array
          argv = argv.dup
          options = nil         # currently never used.
          number = 0
          while argv.size > 0
            current = argv.shift
            if current =~ /^--(.*)/ # a long option
              if @long_options.key?($1)
                command, arguments, options = 
                  extract_command_arguments(argv, @long_options[$1])

                number += 1
                interpreter.context.parsing_option(current, number)
                interpreter.run_command(command, arguments, options)
              else
                raise OptionUnkown, "Long option #{current} is not known"
              end
            elsif current =~ /^-(.*)/ # Short options
              # We do the same as above, but splitting into letters first:
              short_options = $1.split('')
              for short in short_options
                if @short_options.key?(short)
                  command, arguments, options = 
                    extract_command_arguments(argv, @short_options[short])
                  number += 1
                  interpreter.context.parsing_option("-#{short}", number)
                  interpreter.run_command(command, arguments, options)
                else
                  raise OptionUnkown, "Short option -#{short} is not known"
                end
              end
            else
              if @default_command
                argv.unshift current
                command, arguments, options = 
                  extract_command_arguments(argv, @default_command)
                number += 1
                interpreter.context.parsing_option("(default)", number)
                interpreter.run_command(command, arguments, options)
              else
                yield current
              end
            end
          end
        end

        protected
        
        # Prepares the #short_options and #long_options hashes for use
        # in #parse_command_line
        def prepare_option_hashes(default = nil)
          @short_options = {} 
          @long_options = {}
          for cmd in @commands
            short = cmd.short_option
            boolean = (cmd.argument_number == 1 && 
                       cmd.arguments.first.type.boolean?)
            if short 
              if @short_options.key? short
                raise OptionRedefined, "Short option #{short} was already defined as command #{cmd.name}"
              end
              if boolean
                @short_options[short] = [-1, cmd]
              else
                @short_options[short] = [cmd.argument_number, cmd]
              end
            end
            long = cmd.long_option
            if long
              if @long_options.key? short
                raise OptionRedefined, "Long option #{long} was already defined as command #{cmd.name}"
              end
              if boolean
                @long_options[long] = [-1, cmd]
                @long_options["no-#{long}"] = [-2, cmd]
              else
                @long_options[long] = [cmd.argument_number, cmd]
              end
            end
          end
          if default
            @default_command = [default.argument_number, default]
          end
        end

        # Extract command, arguments and potential options from the
        # given _argv_ array. The second argument is what is stored in
        # the #short_options and #long_options hashes.
        #
        # Returns an array
        #  [command, arguments, options]
        def extract_command_arguments(argv, cmd_val)
          number, command = cmd_val
          options = {}

          # Special case for boolean arguments
          if number < 0
            arguments = [number == -1]
          else
            arguments = argv.slice!(0,number)
          end
          
          # We try and go fishing for options, in the form
          # /option=stuff, or /option stuff...
          while argv.first =~ /^\/([\w-]+)(?:=(.*))?$/
            if command.has_option? $1
              argv.shift
              if $2
                options[$1] = $2
              else
                options[$1] = argv.shift
              end
            else
              warn { "Argument #{argv.first} looks like an option, but does not match any of the command #{command.name}" }
              break
            end
          end

          return [command, arguments, options]

        end

      end

    end
  end
end

