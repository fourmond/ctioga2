# strings.rb: the core of the file-based interpretation: strings !
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
require 'stringio'              # For debugging purposes

module CTioga2

  Version::register_svn_info('$Revision: 904 $', '$Date: 2009-03-08 00:55:59 +0100 (Sun, 08 Mar 2009) $')

  module Commands

    class UnterminatedString < Exception
    end

    # All variables and arguments are only strings. There is no type
    # in ctioga, at least not on the variable/strings level. Ruby
    # functions of course work with typed objects, but all user input
    # is taken to be a string and is converted using the
    # CTioga2::Metabuilder::Type system.
    #
    # A string is however not a simple Ruby String, as it can contain
    # elements that are expanded, and it needs to provide a way to be
    # split into substrings for arguments/options processing.
    #
    # A string is composed of an array of [type, value, ... ? ]
    # arrays, where _type_ can have the following meanings:
    # * :unquoted : an unquoted string (can be split)
    # * :unquoted_variable : an unquoted variable (replacement text
    #   can be split)
    # * :quoted : a quoted string (cannot be split)
    # * :quoted_variable : a quoted variable (cannot be split)
    class InterpreterString

      # A small lexical parser. It's job is to carry out the function
      # of InterpreterString.parse_until_unquoted.
      class LexicalAnalyzer
        # The state of the parser:
        # * :start -> first starting elements
        # * :top -> toplevel
        # * :single -> in a single quoted string
        # * :double -> in a double quoted string
        # * :dollar -> last element was a dollar at top-level
        # * :dq_dollar -> last element was an unescaped dollar within
        #   a double quoted string
        # * :escape -> last element was an unescaped escape char
        #   within a double-quoted string.
        # * :var -> in a $(variable)
        # * :dq_var -> in a $(variable) within a double-quoted string
        attr_accessor :state

        # The current string result, as described in InterpreterString
        attr_accessor :parsed

        # The current object on the way of being parsed
        attr_accessor :current_string
        
        # The io device with which the parser is interacting.
        attr_accessor :io

        # The terminating element
        attr_accessor :term

        # Initializes the parser.
        def initialize(io, term)
          @io = io
          @term = term
        end

        # Parse the string from the _io_ object
        def parse(eoerror = true)
          @state = :start
          @parsed = []
          @current_string = ''
          
          i = -1
          while(1)
            c = @io.getc
            if ! c              # EOF
              if eoerror
                raise UnterminatedString, "EOF reached before the end of this string"
              else
                push_current_element
                return @parsed
              end
            end
            # Convert the integer to a string.
            ch = c.chr
            i += 1
            if (@state == :start || @state == :top) and
                (term.include?(ch)) # Finished
              push_current_element
              @io.ungetc(c)     # We push back the last char.
              return @parsed
            end

            # puts "#{@state.inspect} -- #{ch}"

            # We skip white space at the beginning of the string.
            if @state == :start
              # Skip white space
              if ! (ch =~ /\s/)
                @state = :top
              end
            end

            case @state
            when :escape
              # Evaluating escape chars
              @current_string += eval("\"\\#{ch}\"")
              @state = :double
            when :dollar, :dq_dollar
              @state = (@state == :dollar ? :top : :double)
              if ch == '('      # Beginning of a variable within a
                # quoted string
                push_current_element
                @state = (@state == :top ? :var : :dq_var)
              else
                @current_string += "$#{ch}"
              end
            when :single        # The simplest string
              if ch == "'"      # End of string
                push_current_element
                @state = :top
              else
                @current_string += ch
              end
            when :var, :dq_var
              if ch == ")"
                push_current_element
                @state = (@state == :var ? :top : :double)
              else
                @current_string += ch
              end
            when :top
              if ch == "'"      # We start a single-quoted string
                push_current_element
                @state = :single
              elsif ch == '$'   # Dollar state
                @state = :dollar
              elsif ch == '"'
                push_current_element
                @state = :double
              elsif ch == '#'   # A comment: we read until end-of-line
                @io.gets        # and ignore the results
              else
                @current_string += ch
              end
            when :double
              if ch == '"'      # (necessarily unquoted)
                push_current_element
                @state = :top
              elsif ch == '$'
                @state = :dq_dollar
              elsif ch == "\\"
                @state = :escape
              else
                @current_string += ch
              end
            end
          end
          
        end

        # Pushes the element currently being parsed unto the
        # result
        def push_current_element
          if @current_string.size == 0
            return
          end
          case @state
          when :top
            # We push an unquoted string
            @parsed << [:unquoted, @current_string]
          when :single, :double
            @parsed << [:quoted, @current_string]
          when :var
            @parsed << [:unquoted_variable, @current_string]
          when :dq_var
            @parsed << [:quoted_variable, @current_string]
          when :dollar
            @parsed << [:unquoted, @current_string + '$']
          when :dq_dollar
            @parsed << [:quoted, @current_string + '$']
          when :escape
            @parsed << [:quoted, @current_string + "\\" ]
          when :start
            # Empty string at the beginning. Nothing interesting, move
            # along !
          else
            raise "Fatal bug of the lexical analyzer here : unkown state"
          end
          # Flush current string
          @current_string = ""
        end

      end


      # The array of the aforementioned [_type_, _value_, ...] arrays
      attr_accessor :contents
      
      # Read the given _io_ stream until an unquoted element of
      # _term_ is found. Returns the parsed InterpreterString.
      # The terminating element is pushed back onto the stream.
      #
      # If _io_ encounters EOF before the parsing is finished, an
      # UnterminatedString exception is raised, unless the _eoerror_
      # is false.
      #
      # This is the *central* function of the parsing of files.
      def self.parse_until_unquoted(io, term, eoerror = true)
        string = InterpreterString.new
        string.contents = LexicalAnalyzer.new(io, term).parse(eoerror)
        return string
      end

      def initialize(contents = [])
        @contents = contents
      end

      # Fully expand the InterpreterString to obtain a String object.
      # _interpreter_ is the Interpreter object in which the expansion
      # takes place.
      def expand_to_string(interpreter)
        pre_expanded = expand_all_variables(interpreter)
        retval = ""
        for type, value in pre_expanded.contents 
          retval += value
        end
        return retval
      end

      # Splits the string, after expansion, in the *unquoted* parts,
      # where _re_ matches, and returns the corresponding array of
      # strings.
      #
      # An empty expanded string expands to a null array.
      def expand_and_split(re, interpreter)
        pre_expanded = expand_all_variables(interpreter)
        retval = []
        cur_str = ""
        for type, value in pre_expanded.contents
          case type
          when :quoted
            cur_str += value
          when :unquoted
            tmp = value.split(re, -1)
            cur_str += tmp[0]
            # Push splitted stuff here:
            while tmp.size > 1
              retval << cur_str
              tmp.shift
              cur_str = tmp[0]
            end
          end
        end
        retval << cur_str
        if (retval.size == 1) && (retval.first == "")
          return []
        end
        return retval
      end

      protected

      # Returns a new InterpreterString object with all variables
      # expanded. _interpreter_ is the Interpreter in which the
      # expansion takes place.
      def expand_all_variables(interpreter)
        c = []
        for type, value in @contents
          case type
          when :quoted_variable
            c << [:quoted, interpreter.variables.
                  expand_variable(value, interpreter)]
          when :unquoted_variable
            c << [:unquoted, interpreter.variables.
                  expand_variable(value, interpreter)]
          else
            c << [type, value]
          end
        end
        return InterpreterString.new(c)
      end
      

    end

  end

end

