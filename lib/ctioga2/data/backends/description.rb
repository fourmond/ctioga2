# description.rb : a system for
# Copyright (C) 2006, 2009 Vincent Fourmond

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

require 'ctioga2/utils'
require 'ctioga2/data/backends/parameter'
require 'ctioga2/commands/commands'
require 'ctioga2/commands/groups'

module CTioga2

  module Data

    module Backends

      # The Description class is a meta-information class that records several
      # informations about the class:
      #
      # * a basic name, code-like, which is used mainly for internal
      #   purposes;
      # * a long name, more explanatory, in proper English (or any
      #   other language. By the way, it should definitely be
      #   translated in a production environment);
      # * a description itself, some small text describing the nature
      #   of the class;
      # * a list of all the Parameters that are important for the class,
      #   and enough to recreate the state of an object.
      #   
      # This class is fairly general, and can be subclassed to fit specific
      # needs. An example is in the SciYAG/Backend system, where the description
      # of a backend is derived from Description.
      #
      # To make use of the Description system for a class, use the following:
      #
      #   class SomeClass
      #     extend  MetaBuilder::DescriptionExtend
      #     include MetaBuilder::DescriptionInclude
      #     
      #     describe 'someclass', 'Some nice class', <<EOD
      #     The description of a nice class
      #     EOD
      #
      #   end
      #
      # Descriptions can be used in two completely different manners:
      #
      # * you can use a single Description to facilitate the interface
      #   with the user to query|save parameters;
      # * you can use the Description system to describe a whole set of
      #   classes providing similar functions and sharing a base ancestor,
      #   such as series of input|output plugins, database formats,
      #   themes... In this case, the Description system can act as a real
      #   plugin factory, recording every new subclass of the base one
      #   and providing facilities to prompt the user.
      #
      # Please note that if you want to use the facilities to dynamically
      # create objects at run-time, the classes used by describe
      # *should not need any parameter for #initialize*.
      #
      # \todo add functions to prepare commands to set the various
      # parameters
      #
      # \todo write the parameters stuff again...
      class BackendDescription
        # The Class to instantiate. 
        attr_accessor :object_class
        
        # The name of the class (short, code-like)
        attr_accessor :name
        
        # (text) description !
        attr_accessor :description
        
        # Long name, the one for public display
        attr_accessor :long_name

        # The parameter list. The parameters are added when they are found
        # in the class description, and will be used in the order found
        # in this list to recreate the state; beware if one parameter is
        # depending on another one.
        attr_reader   :param_list

        # A hash index on the (short) name and the symbols of the parameters,
        # for quick access. None of those should overlap.
        attr_reader   :param_hash

        # The priority of the CmdGroup
        DefaultBackendGroupPriority = 20
        
        
        # Initializes a Description
        def initialize(cls, name, long_name, description = "", register = true)
          @object_class = cls
          @name = name
          @long_name = long_name
          @description = description
          @param_list = []
          @param_hash = {}
          @init_param_list = []

          if register
            Backend.register_class(self)
          end
        end

        # Adds a new parameter to the description
        def add_param(param)
          @param_list << param

          # Update the parameter hash, for easy access.
          @param_hash[param.reader_symbol] = param
          @param_hash[param.writer_symbol] = param
          @param_hash[param.name] = param

          # Update the current group, if necessary
          @current_group.add_parameter(param) unless @current_group.nil?
        end

        # Creates an instance of the Backend described by this
        # BackendDescription. It takes parameters that are fed
        # to the new function, but don't use them.
        def instantiate(*a)
          return @object_class.new(*a)
        end

        # Creates a set of Cmd to interact with a given
        # Backend. Commands created are:
        # * one for each parameter to allow modification of its type
        # * one for the selection of the Backend, allowing the use of
        #   optional arguments to change (permanently) the behaviour
        #   of the Backend.
        #
        # In addition, this function creates a group to store Backend
        # commands.
        #
        # \todo finish this !!!
        def create_backend_commands
          group = CmdGroup.
            new("backend-#{@name}", 
                "The '#{@name}' backend: #{@long_name}",
                "The commands in this group drive the "+
                "behaviour of the {backend: #{@name}} backend;\n" + 
                "see its documentation for more information",
                DefaultBackendGroupPriority)
          
          backend_options = {}

          # Again, each is needed for scoping problems.
          @param_list.each do |param|
            arg = CmdArg.new(param.type, param.name)
            a = Cmd.new("#{@name}-#{param.name}",
                        nil, "--#{@name}-#{param.name}",
                        [arg], {},
                        "Set the #{param.long_name} parameter of backend '#{@name}'", 
                  param.description, group) do |plotmaker, value|
              plotmaker.data_stack.backend_factory.
                set_backend_parameter_value(@name, param.name, value)
            end
            backend_options[param.name] = arg.dup
          end

          Cmd.new("#{@name}", nil, "--#{@name}", [], 
                  backend_options, "Selects the '{backend: #{@name}}' backend", 
                  nil, group) do |plotmaker, options|
            plotmaker.data_stack.backend_factory.set_current_backend(@name)
            if options
              for k,v in options
                plotmaker.data_stack.backend_factory.
                  set_backend_parameter_value(@name, k, v)
              end 
            end               # Commands#run_command set options to
            # nil if the options hash is an empty hash, so we have to
            # tackle this if it happens
          end
        end

      end

      # This module should be used with +extend+ to provide the class
      # with descriptions functionnalities. Please not that all the
      # *instance* methods defined here will become *class* methods in
      # the class you extend.
      #
      # This module defines several methods to add a description
      # (#describe) to a class, to add parameters (#param,
      # #param_noaccess) and to import parameters from parents
      # (#inherit_parameters).
      #
      # Factories can be created using the #craete_factory statement.
      # This makes the current class the factory repository for all
      # the subclasses. It creates a factory class method returning
      # the base factory.  You can use #register_class to register the
      # current class into the base factory class.
      module BackendDescriptionExtend

        # The functions for factory handling.

        # Makes this class the factory class for all subclasses.  It
        # creates four class methods: base_factory, that always points
        # to the closest factory in the hierarchy and three methods
        # used internally.
        #
        # If _auto_ is true, the subclasses are all automatically
        # registered to the factory. If _register_self_ is true the
        # class itself is registered. It is probably not a good idea,
        # so it is off by default.
        def create_factory(auto = true, register_self = false)
          cls = self
          # we create a temporary module so that we can use
          # define_method with a block and extend this class with it
          mod = Module.new
          mod.send(:define_method, :factory) do
            return cls
          end
          mod.send(:define_method, :private_description_list) do
            return @registered_descriptions
          end
          mod.send(:define_method, :private_description_hash) do
            return @registered_descriptions_hash
          end
          # Creates an accessor for the factory class
          mod.send(:define_method, :private_auto_register) do 
            @auto_register_subclasses
          end
          self.extend(mod)

          # Creates the necessary arrays|hashes to handle the
          # registered classes:
          @registered_descriptions = []
          @registered_descriptions_hash = {}

          @auto_register_subclasses = auto
        end

        # Checks if the class has a factory
        def has_factory?
          return self.respond_to?(:factory)
        end

        # Returns the base description if there is one, or nil if
        # there isn't
        def base_description
          if has_factory?
            return factory.description
          else
            return nil
          end
        end

        # Returns the description list of the factory. Raises an
        # exception if there is no factory
        def factory_description_list
          raise "Must have a factory" unless has_factory?
          return factory.private_description_list
        end

        # Returns the description hash of the factory. Raises an
        # exception if there is no factory
        def factory_description_hash
          raise "Must have a factory" unless has_factory?
          return factory.private_description_hash
        end

        # Returns the factory description with the given name
        def factory_description(name)
          raise "Must have a factory" unless has_factory?
          return factory_description_hash.fetch(name)
        end

        # Returns the Class object associated with the given name in
        # the factory
        def factory_class(name)
          return factory_description(name).object_class
        end

        # Registers the given description to the factory. If no
        # description is given, the current class is registered.
        def register_class(desc = nil)
          raise "One of the superclasses should have a 'factory' statement" unless
            has_factory?
          desc = description if desc.nil?
          factory_description_list << desc
          factory_description_hash[desc.name] = desc
        end
        
        # Returns the Description of the class.
        def description
          return @description
        end
        
        # Sets the description of the class. It is probably way better
        # to use #describe, or write your own class method in the base
        # class in the case of a family of classes.
        def set_description(desc)
          @description = desc
          if has_factory? and factory.private_auto_register
            register_class
          end
        end
        

        # Registers an new parameter, with the following properties:
        # * _writer_ is the name of the method used to write that parameter;
        # * _reader_ the name of the method that returns its current value;
        # * _name_ is a short code-like name of the parameter (typically
        #   lowercase);
        # * _long_name_ is a more descriptive name, properly capitalized and
        #   localized if possible;
        # * _type_ is it's type. Please see the MetaBuilder::ParameterType
        #   for a better description of what is a type;
        # * _desc_ is a proper (short) description of the parameter,
        #   something that would fit on a What's this box, for instance.
        # * _attrs_ are optional parameters that may come useful, see
        #   Parameter#attributes documentation.
        #
        # You might want to use the #param_reader, #param_writer, and
        # #param_accessor facilities that create the respective
        # accessors in addition. A typical example would be:
        #
        #  param :set_size, :size, 'size', "Size", {:type => :integer},
        #  "The size !!"
        def param(writer, reader, name, long_name, type, 
                  desc = "")
          raise "Use describe first" if description.nil? 
          param = nil
          param = Parameter.new(name, writer, reader,
                                long_name, type, desc)
          description.add_param(param)
          return param
        end
        
        # The same as #param, but creates a attr_reader in addition
        def param_reader(writer, reader, name, long_name, type, 
                         desc = "")
          attr_reader reader
          return param(writer, reader, name, long_name, type, desc)
        end

        # The same as #param, except that _writer_ is made from
        # _symbol_ by appending a = at the end. An attr_writer is
        # created for the _symbol_.
        def param_writer(symbol, name, long_name, type, 
                         desc = "")
          writer = (symbol.to_s + '=').to_sym
          attr_writer symbol
          return param(writer, symbol, name, long_name, type, desc)
        end

        # The same as #param_writer, except that an attr_writer is
        # created for the _symbol_ instead of only a attr_writer. The
        # most useful of the four methods. Typical use:
        #
        #  param_accessor :name, 'name', "Object name", {:type => :string},
        #  "The name of the object"
        def param_accessor(symbol, name, long_name, type, 
                           desc = "")
          writer = (symbol.to_s + '=').to_sym
          attr_accessor symbol
          return param(writer, symbol, name, long_name, type, desc)
        end
        
        # Creates a description attached to the current class. It
        # needs to be used before anything else.
        def describe(name, longname = name, desc = "")
          d = Description.new(self, name, longname, desc)
          set_description(d)
        end
        
        
        # Imports the given parameters directly from the parent class.
        # This function is quite naive and will not look further than
        # the direct #superclass.
        def inherit_parameters(*names)
          if self.superclass.respond_to?(:description)
            parents_params = self.superclass.description.param_hash
            for n in names
              if parents_params.key?(n)
                description.add_param(parents_params[n])
              else
                warn { "Param #{n} not found" }
              end
            end
          else
            warn { "The parent class has no description" }
          end
        end
        
      end
      
    end
  end
end
