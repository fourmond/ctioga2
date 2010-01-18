# factory.rb: an object in charge of generating the style for Curves
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

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Styles

      # This object is in charge of the generation of the CurveStyle
      # object for the next curve to be drawn.
      class CurveStyleFactory

        include Log

        # A private class that defines a parameter for the Factory
        class CurveStyleFactoryParameter

          # The code-like name of the parameter
          attr_accessor :name

          # The Commands::CommandType of the parameter
          attr_accessor :type
          
          # The pre-defined sets available to use with that
          # parameter. It is a hash. 
          attr_accessor :sets

          # The description of the parameter.
          attr_accessor :description
          
          # The short option for setting the parameter directly from
          # the command-line.
          attr_accessor :short_option

          # The MetaBuilder::Type object that can convert a String to
          # an Array suitable for use with CircularArray.
          attr_accessor :sets_type

          # If this attribute is on, then CurveStyleFactory will not
          # generate commands for this parameter, only the option.
          attr_accessor :disable_commands
          

          # Creates a new CurveStyleFactoryParameter object.
          def initialize(name, type, sets, description, 
                         short_option = nil, disable_cmds = false)
            @name = name
            @type = Commands::CommandType.get_type(type)
            @sets = sets
            @description = description
            @short_option = short_option
            @disable_commands = disable_cmds
            
            ## \todo it is not very satisfying to mix CommandTypes and
            # MetaBuilder::Type on the same level.
            if @sets
              @sets_type = 
                MetaBuilder::Type.get_type({
                                             :type => :set,
                                             :subtype => @type.type,
                                             :shortcuts => @sets
                                           })
            end
          end

          # Returns a suitable default set for the given object.
          def default_set
            return nil unless @sets
            if @sets.key? 'default'
              return @sets['default']
            else
              @sets.each do |k,v|
                return v
              end
            end
          end

        end

        # Switch some parameter back to automatic
        AutoRE = /auto/i

        # Sets some parameter to _false_.
        DisableRE = /no(ne)?|off/i

        # If that matches, we use the value as a link to other values.
        LinkRE = /(?:=|->)(\S+)/


        # Creates a new parameter for the style factory.
        def self.define_parameter(target, name, type, sets, description, 
                                  short_option = nil, disable_cmds = false)
          # We define two new types:
          # - first, the color-or-auto type:
          base_type = Commands::CommandType.get_type(type)

          if ! Commands::Interpreter.type("#{base_type.name}-or-auto")
            mb_type = base_type.type.dup
            mb_type.re_shortcuts = (mb_type.re_shortcuts ? 
                                        mb_type.re_shortcuts.dup : {}) 
            
            mb_type.re_shortcuts[AutoRE] = 'auto'
            mb_type.re_shortcuts[DisableRE] = false

            # Add passthrough for expressions such as =color...
            mb_type.passthrough = LinkRE

            # Now, register a type for the type or automatic.
            CmdType.new("#{base_type.name}-or-auto", mb_type,
                        "Same thing as type #{base_type.name}, or 'auto'")

          end

          if sets and ! Commands::Interpreter.type("#{base_type.name}-set")
            # Now, register a type for the type or automatic.
            CmdType.new("#{base_type.name}-set",{
                          :type => :set,
                          :subtype => base_type.type,
                          :shortcuts => sets
                        } ,
                        "Sets of #{base_type.name}")
          end
          param = 
            CurveStyleFactoryParameter.new(name, type, sets, 
                                           description, short_option, 
                                           disable_cmds)
          @parameters ||= {}
          @parameters[target] = param

          @name_to_target ||= {}
          @name_to_target[name] = target
        end

        # Returns the Hash containing the class parameters.
        def self.parameters
          return @parameters || {}
        end


        # Returns the Hash containing the class parameters.
        def self.name_to_target
          return @name_to_target
        end

        # The CmdGroup for stylistic information about
        # curves.
        CurveStyleGroup = 
          CmdGroup.new('curve-style', "Curve styles", 
                       "Set stylistic details about curves", 1)


        # Creates two commands for each parameter of the object:
        # * a command to set the override
        # * a command to choose the sets.
        def self.create_commands
          parameters.each do |target, param|
            next if param.disable_commands
            override_cmd = 
              Cmd.new("#{param.name}",
                      param.short_option,
                      "--#{param.name}", 
                      [
                       CmdArg.new("#{param.type.name}-or-auto") 
                      ], {},
                      "Sets the #{param.description} for subsequent curves",
                      "Sets the #{param.description} for subsequent curves, until cancelled with 'auto' as argument.", CurveStyleGroup) do |plotmaker, value|
              plotmaker.curve_generator.style_factory.
                set_parameter_override(target, value)
            end

            if param.sets
              next if param.disable_commands
              set_cmd = 
                Cmd.new("#{param.name}-set",
                        nil,
                        "--#{param.name}-set", 
                        [
                         CmdArg.new("#{param.type.name}-set")
                        ], {},
                        "Chooses a set for the #{param.description} of subsequent curves",
                        "Chooses a set for the #{param.description} of subsequent curves", 
                        CurveStyleGroup) do |plotmaker, value|
                plotmaker.curve_generator.style_factory.
                  set_parameter_set(target, value)
              end
            end
          end
        end

        # This function returns a hash suitable for use with the plot
        # command as optional arguments, that will end up as the
        # _one_time_ hash in #next.
        def self.plot_optional_arguments
          args = {}
          for option_name, param in @parameters
            args[param.name] = 
              CmdArg.new(param.type)
          end

          # Here, we add the support for a /legend= option
          args['legend'] = CmdArg.new('text')
          @name_to_target['legend'] = 'legend'

          return args
        end


        # A hash containing values that override default ones derived
        # from the CircularArray objects.
        attr_accessor :override_parameters

        # A hash of CircularArray objects.
        attr_accessor :parameter_carrays


        # Creates a new CurveStyleFactory.
        def initialize
          # Overrides as in the first ctioga
          @override_parameters = {
            'line_style' => LineStyles::Solid,
            'marker_marker' => false,
            'marker_scale' => 0.5 
          }
          @parameters_carrays = {}
          for target, param in self.class.parameters
            set = param.default_set
            if set
              @parameters_carrays[target] = CircularArray.new(set)
            end
          end
        end

        # Gets the style for the next curve. The _one_time_ hash
        # contains values 'parameter name' (name, and not target) =>
        # value that are used for this time only.
        def next(one_time = {})
          base = {}
          for target, array in @parameters_carrays
            base[target] = array.next
          end
          base.merge!(@override_parameters)
          base.merge!(hash_name_to_target(one_time))
          return CurveStyle.from_hash(resolve_links(base))
        end



        # Sets the override for the given parameter. This corresponds
        # to fixing manually the corresponding element until the
        # override is removed, by a call with a _value_ that matches
        # AutoRE.
        #
        # The _value_ should ideally be a String that is further
        # converted to the appropriate type. Non-string objects will
        # be left untouched.
        def set_parameter_override(target, value)
          param = get_parameter(target)
          # Perform automatic type conversion only on strings.
          if value.is_a? String 
            if value =~ AutoRE
              @override_parameters.delete(target)
              return
            elsif value =~ LinkRE
              t = $1
              convert = self.class.name_to_target
              if convert.key?(t)
                value = "=#{convert[t]}".to_sym
              else
                warn "No known key: #{t}, treating as auto"
                @override_parameters.delete(target)
                return
              end

            elsif value =~ DisableRE
              value = false
            else
              value = param.type.string_to_type(value)
            end
          end

          @override_parameters[target] = value
        end

        # Sets the CircularArray set corresponding to the named
        def set_parameter_set(target, value)
          param = get_parameter(target)
          # Perform automatic type conversion only on strings.
          if value.is_a? String 
            value = param.sets_type.string_to_type(value)
          end
          @parameters_carrays[target].set = value
        end

        # Now, the parameters:

        # Lines:
        define_parameter 'line_color', 'color', 'color',
        Sets::ColorSets, "color", "-c"

        define_parameter 'line_width', 'line-width', 'float',
        Sets::LineWidthSets, "line width", nil

        define_parameter 'line_style', 'line-style', 'line-style',
        Sets::LineStyleSets, "line style", nil

        # Markers
        define_parameter 'marker_marker', 'marker', 'marker',
        Sets::MarkerSets, "marker", '-m'

        define_parameter 'marker_color', 'marker-color', 'color',
        Sets::ColorSets, "marker color", nil

        define_parameter 'marker_scale', 'marker-scale', 'float',
        Sets::LineWidthSets, "marker scale", nil

        # Error bars:
        define_parameter 'error_bar_color', 'error-bar-color', 'color',
        Sets::ColorSets, "error bar color", nil

        # Location:
        define_parameter 'location_xaxis', 'xaxis', 'axis',
        nil, "X axis", nil, true

        define_parameter 'location_yaxis', 'yaxis', 'axis',
        nil, "Y axis", nil, true

        # And finally, we register all necessary commands...
        create_commands

        # A constant suitable for use as the optional arguments of the
        # plot command.
        PlotCommandOptions = plot_optional_arguments

        protected

        # Returns the CurveFactoryParameterType object corresponding
        # to the named parameter.
        def get_parameter(target)
          if ! parameters.key? target
            raise "Unkown parameter: #{target}"
          else
            return parameters[target]
          end
        end

        # Returns the class parameters hash
        def parameters
          return self.class.parameters
        end

        # Converts the one-time parameters, which is a hash whose keys
        # are the names of the parameters to targets.
        def hash_name_to_target(h)
          retval = {}
          convert = self.class.name_to_target
          for k,v in h
            if convert.key? k 
              retval[convert[k]] = v
            else
              warn "Unkown key for hash_name_to_target: #{k}"
            end
          end
          return retval
        end

        # Resolve potential links in the form of :=stuff within the
        # given hash, and returns a new version of the hash.
        #
        # \warning the _h_ parameter is completely destroyed in the
        # process
        def resolve_links(h)
          tv = {}

          # First, copy plain values
          for k,v in h
            if v.is_a?(Symbol) && v.to_s =~ /^(=|->)/
              # We keep for later
            else
              tv[k] = v
              h.delete(k)
            end
          end
          
          # Now, we will iterate over the remaining things; we will
          # stop with an error if the number of remaining keys does
          # not decrease after one step
          while h.size > 0
            pre_size = h.size
            for k,v in h
              v.to_s =~ /^(?:=|->)(\S+)/
              target = $1
              if tv.key? target
                tv[k] = tv[target]
                h.delete(k)
              end
            end
            if h.size >= pre_size
              raise "Error: infinite recursion loop while gathering styles"
            end
          end
          
          return tv
        end
      end
    end
  end
end

