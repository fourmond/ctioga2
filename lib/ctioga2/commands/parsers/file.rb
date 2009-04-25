# file.rb: a file parser for ctioga2
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'stringio'
require 'ctioga2/utils'
require 'ctioga2/log'
require 'ctioga2/commands/commands'
require 'ctioga2/commands/strings'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    module Parsers

      # Raised when EOF is encountered during a symbol parsing
      class UnterminatedSymbol < Exception
      end

      # Unexepected character.
      class UnexpectedCharacter < Exception
      end

      # Syntax error
      class ParserSyntaxError < Exception
      end

      # This class is in charge of parsing a command-line against a list
      # of known commands. 
      class FileParser

        include Log

        # Runs a command file targeting the given _interpreter_.
        def self.run_command_file(file, interpreter)
          FileParser.new.run_command_file(file, interpreter)
        end

        # Runs the given command strings
        def self.run_commands(strings, interpreter)
          FileParser.new.run_commands(strings, interpreter)
        end

        # Runs a command file targeting the given _interpreter_.
        def run_command_file(file, interpreter)
          f = open(file)
          parse_io_object(f, interpreter)
        end

        # Runs the given command strings
        def run_commands(strings, interpreter)
          io = StringIO.new(strings)
          parse_io_object(io, interpreter)
        end

        # Parses a given _io_ object, sending commands/variable
        # definitions to the given _interpreter_.
        def parse_io_object(io, interpreter)
          # The process is simple: we look for symbols and
          # corresponding syntax element: parentheses or assignments
          while(1)
            symbol = up_to_next_symbol(io)
            break if not symbol
            
            while(1)
              c = io.getc
              if ! c              # EOF
                raise ParserSyntaxError, "Expecting something after symbol #{symbol}"
              end
              ch = c.chr
              if ch =~ /\s/      # blank...
                next
              elsif ch == '('    # beginning of a function call
                # Parse string:
                str = InterpreterString.parse_until_unquoted(io,")")
                # Now, we need to split str.
                args = str.expand_and_split(/\s*,\s*/, interpreter)

                cmd = interpreter.get_command(symbol)
                real_args = args.slice!(0, cmd.argument_number)
                # And now the options:
                options = {}

                # Problem: the space on the right of the = sign is
                # *significant*. 
                for o in args
                  if o =~ /^\s*([\w-]+)\s*=(.*)/
                    if cmd.has_option? $1
                      options[$1] = $2
                    else
                      error "Command #{cmd.name} does not take option #{$1}"
                    end
                  end
                end

                interpreter.run_command(cmd, real_args, options)
                io.getc         # Slurp up the )
                break
              elsif ch == ':'   # Assignment
                c = io.getc
                if ! c          # EOF
                  raise ParserSyntaxError, "Expecting = after :"
                end
                ch = c.chr
                if ch != '='
                  raise ParserSyntaxError, "Expecting = after :"
                end
                str = InterpreterString.parse_until_unquoted(io,"\n", false)
                interpreter.variables.define_variable(symbol, str, 
                                                      interpreter)
                break
              elsif ch == '='
                str = InterpreterString.parse_until_unquoted(io,"\n", false)
                interpreter.variables.define_variable(symbol, str, nil) 
                break
              else
                raise UnexpectedCharacter, "Did not expect #{ch} after #{symbol}"
              end
            end
          end
        end

        protected

        SYMBOL_CHAR_REGEX = /[a-zA-Z0-9_-]/
        
        # Parses the _io_ stream up to and including the next
        # symbol. Only white space or comments may be found on the
        # way. This function returns the symbol.
        #
        # Symbols are composed of the alphabet SYMBOL_CHAR_REGEX.
        def up_to_next_symbol(io)

          symbol = nil          # As long as no symbol as been started
          # it will stay nil.
          while(1)
            c = io.getc
            if ! c              # EOF
              if symbol
                raise UnterminatedSymbol, "EOF reached during symbol parsing"
              else
                # File is finished and we didn't meet any symbol.
                # Nothing to do !
                return nil
              end
            end
            ch = c.chr
            if symbol           # We have started
              if ch =~ SYMBOL_CHAR_REGEX
                symbol += ch
              else
                io.ungetc(c)
                return symbol
              end
            else
              if ch =~ SYMBOL_CHAR_REGEX
                symbol = ch
              elsif ch =~ /\s/
                # Nothing
              elsif ch == '#'
                io.gets
              else
                raise UnexpectedCharacter, "Unexpected character: #{ch}, when looking for a symbol"
              end
            end
          end
        end

      end

    end
  end
end

