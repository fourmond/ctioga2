# type.rb : a framework for type-to-string-to-type conversion
# Copyright (C) 2006-2009 Vincent Fourmond
 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
# USA

require 'ctioga2/utils'

module CTioga2
  

  # The MetaBuilder module contains a framework to perform
  # string-to-type conversion and other stuff that can be useful for backends.
  module MetaBuilder

    # An exception that must be raised when
    # Type#string_to_type is given incorrect input.
    class IncorrectInput < Exception
    end
    
    # An exception raised when an invalid type is given to the
    class InvalidType < Exception
    end


    # A class that handles a parameter type. It has to be subclassed to
    # actually provide a parameter. The subclasses must provide the
    # following:
    #
    # * a #string_to_type function to convert from string to the type;
    # * a #type_to_string to convert back from type to string
    # * an instance #type_name that returns a really small description
    #   of the type, to be used for instance to name command-line parameters.
    # * a #type_name statement that registers the current class to the
    #   Type system.
    #
    # Moerover, it is a good idea to reimplement the
    # #qt4_create_input_widget method; the default implementation works,
    # but you probably wish it would look better.
    #
    # Types are implemented using hashes: this way, additionnal
    # parameters can easily be added. The hash *must* have a :type key
    # that will be interpreted by the children of Type. Examples:
    #
    #  { :type => :integer}
    #  { :type => :file, :filter => "Text Files (*.txt)}
    #
    # And so on. You definitely should document your type and it's
    # attributes properly, if you ever want that someone uses it.
    #
    # The list of currently recognised types is here:
    # 
    # <tt>:integer</tt> ::   Types::IntegerParameter
    # <tt>:float</tt> ::     Types::FloatParameter
    # <tt>:string</tt> ::    Types::StringParameter
    # <tt>:file</tt> ::      Types::FileParameter
    # <tt>:boolean</tt> ::   Types::BooleanParameter
    # <tt>:list</tt> ::      Types::ListParameter
    #
    # Additionally to the parameters the given type is requiring, you can
    # pass some other kind of information using this hash, such as option
    # parser short argument, aliases, and so on. This has nothing to do
    # with type conversion, but it is the best place where to put this kind
    # of things, in my humble opinion. The currently recognized such additional
    # parameters are:
    # * :option_parser_short: a short option name for option_parser.
    # * :namespace: a ruby module that will be searched by #string_to_type
    #   for a constant. If one of the given name is found, its value is
    #   returned.
    # * :shortctus: a hash specifiying strings shortcuts for given values.
    #   Elements of this hash that are regular expressions are taken
    class Type

      # A hash that makes the :type value of the _type_ argument correspond
      # to a Type child
      @@types = { }

      # The initial type specification that was given to the Type
      attr_accessor :type

      # A hash shortcut -> value. Can be _nil_
      attr_accessor :shortcuts

      # A hash Regexp -> value. All elements will be looked for
      # matches for every single string conversion, so don't dump too
      # many of them here.
      attr_accessor :re_shortcuts

      # If the given string matches this regular expression, it is
      # passed through without further modification.
      attr_accessor :passthrough

      # An array of module whose constants can be used "as such"
      attr_accessor :namespace

      # When a :namespace option is provided, this hash provides a
      # lookup 'lowercase name' => constant value.
      attr_accessor :namespace_lookup

      # A default constructor. It should be safe to use it directly for
      # children, unless something more specific is needed. Any descendent
      # should *always* register _type_ as @type - or, even better, call
      # super.
      def initialize(type)
        if type.is_a?(Symbol)
          type = {:type => type}
        end
        @type = type
        if @type[:shortcuts]
          @shortcuts = @type[:shortcuts]
          @re_shortcuts = {}
          for k,v in @shortcuts
            if k.is_a? Regexp
              @re_shortcuts[k] = v
            end
          end
        end
        if @type[:passthrough]
          @passthrough = @type[:passthrough]
        end

      end


      # This class function actually registers the current type
      # to the Type ancestor. _name_ should be a symbol.
      # Moreover, if the second argument is provided, it automatically
      # creates a #type_name instance method returning this value.
      def self.type_name(name, public_name = nil, default_value = nil)
        if @@types.has_key?(name)
          warn { "Redefining type #{name} " +
            "from #{@@types[name]} to #{self}" }
        end
        @@types[name] = self
        self.send(:define_method,:type_name) do
          public_name
        end
        self.send(:define_method,:default_value) do
          default_value
        end
      end      

      # This function converts a 'description' (see the Type) of the
      # type wanted into a Type child.  As a special treat, a lone
      # symbol is converted into {:type => :symbol}
      def self.get_param_type(type)
        if type.is_a?(Symbol)
          type = {:type => type}
        end
        raise InvalidType,"The type argument must be a Hash" unless 
          type.is_a?(Hash)
        begin
          return @@types.fetch(type[:type])
        rescue
          raise InvalidType, "Type #{type[:type]} unknown to the type system"
        end
      end

      # Shortcut to convert directly a string to the given type specification.
      # Handy shortcut.
      def self.from_string(type, string)
        return get_type(type).string_to_type(string)
      end

      # Returns a Type child instance suitable for conversion
      # of the given type specification
      def self.get_type(type)
        if type.is_a? Type
          return type
        end
        return get_param_type(type).new(type)
      end

      

      # This function converts the given string to the appropriate
      # type. It is a wrapper around the #string_to_type_internal
      # function that can take advantage of a few general features. It
      # is recommanded to define a #string_to_type_internal function
      # rather to redefine #string_to_type
      def string_to_type(string)
        # First, passthrough
        if @passthrough && @passthrough === string
          return stt_run_hook(string)
        end
        # First, shortcuts:
        if @shortcuts and @shortcuts.key? string
          return stt_run_hook(@shortcuts[string])
        end
        if @re_shortcuts
          for k, v in @re_shortcuts
            if string =~ k
              return stt_run_hook(v)
            end
          end
        end

        # Then, constants lookup.
        if @type.key?(:namespace)
          begin
            return stt_run_hook(lookup_const(string))
          rescue IncorrectInput
          end
        end
        return stt_run_hook(string_to_type_internal(string))
      end

      # This function does the exact opposite of the #string_to_type
      # one. It defaults to using the to_s methods of the
      # parameter. Be careful: it is absolutely important that for any
      # valid type,
      #
      #   string_to_type(type_to_string(type)) == type
      def type_to_string(type)
        return type_to_string_internal(type)
      end


      # Returns a default value for the given type. This is
      # reimplemented systematically from children, with the
      # Type::type_name statement.
      def default_value
      end


      # Returns a type name suitable for displaying, for instance, in
      # an option parser, or inside a dialog box, and so on. Has to be
      # one word (not to confuse the option parser, for instance); it
      # is better if it is lowercase.
      def type_name
        return 'notype'
      end


      # Creates an option for the OptionParser _parser_. The block is
      # fed with the converted value. The default implementation
      # should be fine for most classes, but this still leaves the
      # room for reimplementation if necessary. The parameters are:
      # 
      # * _parser_: the OptionParser;
      # * _name_: the name of the option;
      # * _desc_: it description,
      # * _block_: the block used to set the data.
      def option_parser_option(parser, name, desc, &block)
        args = [option_parser_long_option(name), desc]
        if @type.has_key?(:option_parser_short)
          args.unshift(@type[:option_parser_short])
        end
        option_parser_raw(parser, *args, &block)
      end

      # Returns a value to be fed to OptionParser#on as a 'long'
      # option.  It is separated from the rest to allow easy
      # redefinition (in special cases). _name_ is the name of the
      # option.
      def option_parser_long_option(name, param = nil)
        param ||= type_name
        param = param.gsub(/\s+/, '_')
        return "--#{name} #{param.upcase}"
      end

      # Whether the type is a boolean. Booleans are special cased for
      # their use in the command-line.
      def boolean?
        return false
      end

      ############################################################
      # Part of the internal implementation of Types. This should be
      # used/redefined in children
      
      protected

      def build_namespace_lookup
        if @type[:namespace]
          @namespace = [@type[:namespace]].flatten

          @namespace_lookup = {}
          for m in @namespace
            for c in m.constants
              @namespace_lookup[c.to_s.downcase] = m.const_get(c)
            end
          end
        end

      end

      # Looks for the value as a constant specified in the :namespace
      # modules. Raises IncorrectInput if not found.
      def lookup_const(str)
        str = str.downcase
        if @type[:namespace] && (! @namespace_lookup)
          build_namespace_lookup
        end
        if @namespace_lookup.key? str
          return @namespace_lookup[str]
        else
          raise IncorrectInput, "Constant #{str} not found"
        end
      end
      
      # The internal function for converting type to a string. Used by
      # #type_to_string, children should only reimplement this
      # function and leave #type_to_string
      def type_to_string_internal(type)
        return type.to_s
      end
      

      # Runs the string_to_type conversion hook
      def stt_run_hook(val)
        if @type.key?(:stt_hook)
          return @type[:stt_hook].call(val)
        else
          val
        end
      end

      # Does the actual conversion from a _string_ to the
      # type. Redefine this in children.
      def string_to_type_internal(string)
        raise "The class #{self.class} should not be used by itself for conversion"
      end

      # Creates on option for the OptionParser _parser_. The _args_
      # will be fed directly to OptionParser#on. The _block_ is called
      # with the value in the target type.
      def option_parser_raw(parser, *args, &block)
        b = block                 # For safe-keeping.
        c = proc do |str|
          b.call(string_to_type(str))
        end
        parser.on(*args, &c)
      end

    end
  end
end
