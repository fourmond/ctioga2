# file.rb: new style file parser for ctioga2
# copyright (c) 2013 by Vincent Fourmond
  
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
require 'ctioga2/commands/strings'
require 'ctioga2/commands/parsers/old-file'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    module Parsers

      # This class parses a "new style" command file, delegating
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

          # We first split everything into lines
          lines = io.readlines
          
          # First, we look for old-style commands to see if we
          # delegate to the other parser. In any case, we build up a
          # list of "unsplit" lines (ie gather lines that end with \)

          parsed_lines = []
          cur = nil 

          ## @todo line counting ?
          for l in lines
            # If we find something that looks like a command at the
            # beginning of a line, we say this is an old style file.

            ## @todo Find a way to disable this compatibility stuff --
            ## or make it more accurate ? The problem is that in a
            ## large command file, there may be things that look like
            ## old style commands ?
            
            if l =~ /^([a-z0-9-]+)\(/
              info { "Found old style commands, using old style parser"}
              return OldFileParser.new.
                run_commands(lines.join(""), interpreter)
            end
            if cur
              cur << l
            else
              cur = l
            end

            if cur =~ /\\$/ 
              cur.gsub!(/\\$/,'')
              cur = chomp(cur)
            else
              parsed_lines << cur
              cur = nil
            end
            
          end

          # Flush any pending unfinished line
          parsed_lines << cur if cur

          # Now, we rearrange the lines...
          for l in parsed_lines
            if l =~ /^\s*([a-zA-Z0-9_-]+)\s*(=|:=)\s*(.*)/
              symbol = $1
              value = InterpreterString.parse_until_unquoted(StringIO.new($3),"\n", false)
              rec = (($2 == "=") ? nil : interpreter)
                      
              interpreter.variables.define_variable(symbol, value, rec)
            elsif l =~ /^\s*#/
                # comment...
            else
              l += "\n"
              str = InterpreterString.parse_until_unquoted(StringIO.new(l),"\n")
              words = str.expand_and_split(/\s+/, interpreter)

              # Take care of strings starting with spaces...
              
              if words.size == 0
                next
              end
              
              symbol = words[0]
              all_args = words[1..-1]
              
              cmd = interpreter.get_command(symbol)

              args, opts = parse_args_and_opts(cmd, all_args)

              interpreter.context.parsing_file(symbol, io) # Missing line number
              interpreter.run_command(cmd, args, opts)
            end
          end
        end
          
        protected
         
        
        # Parses the all_args into arguments and options.
        def parse_args_and_opts(cmd, all_args)
          
          opts = {}
          args = []
          while all_args.size > 0
            a = all_args.shift
            if a =~ /^\/([a-zA-Z0-9_-]+)(=(.*))?$/
              o = $1
              if cmd.has_option?(o)
                if $2
                  if $3
                    opts[o] = $3
                  else
                    opts[o] = all_args.shift
                  end
                else
                  nxt = all_args.shift
                  if nxt =~ /^\s*=\s*$/
                    opts[o] = all_args.shift
                  else
                    opts[o] = nxt.gsub(/^\s*=/,'')
                  end
                end
              else
                warn { "#{o} looks like an option, but command #{cmd.name} does not have such an option" }
                args << a
              end
            else
              args << a
            end
          end

          return [args, opts]
        end
      end

    end
  end
end

