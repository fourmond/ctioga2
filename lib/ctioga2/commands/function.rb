# function.rb: makefile-like functions
# copyright (c) 2014 by Vincent Fourmond
  
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

  module Commands

    # A Function is a makefile-like "macro" or "function" that takes
    # one or more arguments (no argumentless functions for now).
    #
    # This class provides both the definition and handling of a
    # function and the global registry of functions.
    class Function

      # The underlying proc object. The first argument to the code is
      # *always* the plotmaker object.
      attr_accessor :code

      # The name of the function. Probably better lowercase ?
      attr_accessor :name

      # A short description
      attr_accessor :short_description

      # Long description, ie a help text like the rest
      attr_accessor :description

      # Registers a function.
      #
      # @todo Have self-documenting capacities !
      def initialize(name, short_desc, &blk)
        @code = blk
        @name = name
        @short_description = short_desc
        
        Function.register(self)
      end

      def describe(txt)
        @description = txt
      end

      # Expands the function, and returns the corresponding string.
      def expand(string, interpreter)
        if @code.arity == 2
          args = [string.expand_to_string(interpreter)]
        else
          args = string.expand_and_split(/\s+/, interpreter)
        end
        if (@code.arity > 0) and (args.size != (@code.arity - 1))
          raise "Function #{@name} expects #{@code.arity} arguments, but was given #{args.size}"
        end
        return @code.call(interpreter.plotmaker_target, *args).to_s
      end

      # Registers the given function definition
      def self.register(func)
        @functions ||= {}
        @functions[func.name] = func
      end

      # Returns the named function definition, or nil if there isn't
      # such.
      def self.named_function(name)
        return @functions[name]
      end

      # Returns the functions hash
      def self.functions
        return @functions
      end
      
    end
  end

end

