# variables.rb: the variable system for the commands
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
require 'ctioga2/commands/strings'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    class RecursiveExpansion < Exception
    end

    # A holder for variables. Variables in ctioga2 are very similar to
    # the ones found in make(1).
    # They are only pieces of text that are expanded using the
    #  $(variable)
    # syntax, just like in make.
    # 
    # There are two kind of variables
    # * immediate, defined by
    #    variable := value
    #   or
    #   These ones are evaluated for once when they are defined.
    #   They are stored in the form of a String
    # * recursively expanded variables. They are mostly like immediate
    #   variables, excepted that the values of the replacement texts
    #   for variables used within are expanded at the moment the
    #   variable is expanded, and not at the moment of its definition
    #   as before. They are defined by
    #    variable = value
    #   They are stored in the form on an InterpreterString
    # 
    # \todo The variables system should automatically transform
    # recursive variables into immediate ones when there is no
    # variables replacement text.
    class Variables

      # A hash "variable name" => String or InterpreterString
      attr_accessor :variables

      # Creates a new empty Variables object
      def initialize
        @variables = {}
      end

      # Sets a the variable _name_ to _value_ (being an
      # InterpreterString or a String). If _interpreter_ is given, the
      # value is expanded at the time of the definition, (immediate
      # variable), whereas if it stays _nil_, the variable is defined
      # as a recursively defined variable.
      def define_variable(name, value, interpreter = nil)
        if value.respond_to? :expand_to_string
          if interpreter
            value = value.expand_to_string(interpreter)
          end
        end
        @variables[name] = value
      end

      # Fully expands a variable. Returns a String.  _name_ is the
      # name of the variable, and _interpreter_ the context in which
      # the expansion will take place.
      #
      # *Note* it is assumed here that the variables live in the
      # _interpreter_.
      def expand_variable(name, interpreter)
        if @variables.key? name
          var = @variables[name]
          if var.respond_to? :expand_to_string
            begin
              return var.expand_to_string(interpreter)
            rescue SystemStackError
              raise RecursiveExpansion, "The stack smashed while expanding variable #{name}. This probably means it is a recursive variable referring to itself. Use := in the definition to avoid that"
            end
          else
            return var
          end
        else
          return ""
        end
      end

    end

  end

end

