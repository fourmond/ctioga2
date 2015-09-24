# factory.rb: an object in charge of generating the style for Curves
# copyright (c) 2009, 2013 by Vincent Fourmond

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

          # The name of the default set, when it isn't 'default'
          attr_accessor :default_set

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
            @type = type
            if sets
              # If the sets is an array, it is of the form [sets, 'default set']
              if sets.is_a? Array
                @sets = sets[0]
                @default_set = sets[1]
              else
                @sets = sets
              end
            end
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
            if @default_set
              return @sets[@default_set]
            elsif @sets.key? 'default'
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
        def self.define_parameter(target, name, sets, description, 
                                  short_option = nil, disable_cmds = false)
          # We define two new types:
          # - first, the color-or-auto type:
          base_type = CurveStyle.attribute_type(target)

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
                        "Same thing as {type:#{base_type.name}}, or @auto@ to let the style factory handle automatically.")

          end

          if sets and ! Commands::Interpreter.type("#{base_type.name}-set")
            # Now, register a type for the type or automatic.
            CmdType.new("#{base_type.name}-set",{
                          :type => :set,
                          :subtype => base_type.type,
                          :shortcuts => sets
                        } ,
                        "Sets of {type: #{base_type.name}}")
          end
          param = 
            CurveStyleFactoryParameter.new(name, base_type, sets, 
                                           description, short_option, 
                                           disable_cmds)
          @parameters ||= {}
          @parameters[target] = param

          @name_to_target ||= {}
          @name_to_target[name] = target
        end

        # A simple parameter is something whose target defines all, ie
        # only the name and a documentation text is necessary.
        def self.simple_parameter(target, text, sets = nil, short = nil)
          name = target.gsub(/_/, '-')
          define_parameter(target, name, sets, text, short)
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
          CmdGroup.new('curve-style', "Curves styles", 
                       "Set stylistic details of curves or other object drawn from data", 1)


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
                      "Sets the #{param.description} for subsequent curves, until cancelled with @auto@ as argument.", CurveStyleGroup) do |plotmaker, value|
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
                        "Chooses a set for the #{param.description} of subsequent curves. Also sets {command: #{param.name}} to @auto@, so that the set takes effect immediately", 
                        CurveStyleGroup) do |plotmaker, value|
                plotmaker.curve_generator.style_factory.
                  set_parameter_set(target, value)
                plotmaker.curve_generator.style_factory.
                  set_parameter_override(target, 'auto')
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
            'marker' => false,
            'marker_scale' => 0.5,
            'fill_color' => '=color'.to_sym,
            'error_bar_color' => '=marker_color'.to_sym
          }
          @parameters_carrays = {}
          for target, param in self.class.parameters
            # There should be a way to do that !
            set = param.default_set
            if set
              @parameters_carrays[target] = CircularArray.new(set)
            end
          end

          @next_style = nil
        end

        # Sets the style to be returned from the next call to #next
        # (not counting the effect of the options passed)
        def set_next_style(stl)
          @next_style = stl
        end

        # Gets the style for the next curve. The _one_time_ hash
        # contains values 'parameter name' (name, and not target) =>
        # value that are used for this time only.
        def next(one_time = {})
          if @next_style
            base = @next_style
            @next_style = nil
          else
            base = {}
            for target, array in @parameters_carrays
              base[target] = array.next
            end
            base.merge!(@override_parameters)
          end
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
                warn { "No known key: #{t}, treating as auto" }
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
        simple_parameter 'color', "line color", Sets::ColorSets,  "-c"

        simple_parameter 'line_width', 'line width', Sets::LineWidthSets

        simple_parameter 'line_style', 'line style', Sets::LineStyleSets

        # Markers
        simple_parameter 'marker', 'marker', Sets::MarkerSets, '-m'

        simple_parameter 'marker_color', "marker color", Sets::ColorSets

        simple_parameter 'marker_fill_color', "marker fill color", [Sets::ColorSets, 'nil']

        simple_parameter 'marker_line_color', "marker stroke color", [Sets::ColorSets, 'nil']

        simple_parameter 'marker_scale', "marker scale", Sets::LineWidthSets

        simple_parameter 'marker_angle', "marker angle", nil

        simple_parameter 'marker_line_width', "marker line width", nil 

        simple_parameter 'marker_min_scale', "marker scale", nil

        # Error bars:
        simple_parameter 'error_bar_color', "error bar color", 
        Sets::ColorSets

        simple_parameter 'error_bar_line_width', "error bar line width", 
        Sets::LineWidthSets

        # Location:
        define_parameter 'location_xaxis', 'xaxis', 
        nil, "X axis", nil, true

        define_parameter 'location_yaxis', 'yaxis', 
        nil, "Y axis", nil, true

        # Now, fill style
        simple_parameter 'fill', 'Fill until', {}

        simple_parameter 'fill_color', "fill color", Sets::ColorSets

        simple_parameter 'fill_pattern', "fill pattern", nil

        simple_parameter 'clipped', "clipped", nil

        simple_parameter 'depth', "depth", nil

        simple_parameter 'fill_transparency', 'fill transparency', {}

        # Region handling
        define_parameter 'region_position', 'region-side', 
        {"default" => [:above, :below]}, "region side", nil


        simple_parameter 'path_style', 'path style', {}

        # Only for xyz-maps or xy-parametric
        simple_parameter 'color_map', 'color map'

        simple_parameter 'zaxis', "name for the Z axis"

        simple_parameter 'marker_color_map', 'color map for markers'
        simple_parameter 'marker_line_color_map', 'color map for the lines of markers'
        simple_parameter 'marker_fill_color_map', 'color map for the lines of markers'
        simple_parameter 'split_on_nan', 'split on NaN'


        # Contour plot styles
        simple_parameter 'contour_conrec', "use CONREC for contouring"
        simple_parameter 'contour_number', "overall number of level lines"
        simple_parameter 'contour_minor_number', "number of minor level lines between major ones (approx)"
        simple_parameter 'contour_minor_scale', "relative scale of minor level lines"
        simple_parameter 'contour_minor_style', "minor ticks line style"


        # And finally, we register all necessary commands...
        create_commands

        # A constant suitable for use as the optional arguments of the
        # plot command.
        PlotCommandOptions = plot_optional_arguments

        # Converts the one-time parameters, which is a hash whose keys
        # are the names of the parameters to targets.
        def hash_name_to_target(h)
          retval = {}
          convert = self.class.name_to_target
          for k,v in h
            if convert.key? k 
              retval[convert[k]] = v
            else
              warn { "Unkown key for hash_name_to_target: #{k}" }
            end
          end
          return retval
        end

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
              if CurveStyleFactory.name_to_target[target]
                target = CurveStyleFactory.name_to_target[target]
              end
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

      SkipCommand = 
        Cmd.new("skip",nil,"--skip", 
                [], {'number' => CmdArg.new("integer")}
               ) do |plotmaker, opts|
        number = opts['number'] || 1
        fct = plotmaker.curve_generator.style_factory
        while number > 0
          number -= 1
          fct.next
        end
      end

      SkipCommand.describe('Skips next curve style', 
                           <<EOH, CurveStyleFactory::CurveStyleGroup)
This command acts as if one (or @number@) dataset had been drawn with 
respect to the style of the next dataset to be drawn.
EOH

      ReuseCommand = 
        Cmd.new("reuse-style",nil,"--reuse-style", 
                [CmdArg.new('object')], {}
               ) do |plotmaker, obj, opts|
        stl = obj.curve_style.to_hash
        plotmaker.curve_generator.style_factory.set_next_style(stl)
      end

      ReuseCommand.describe('Reuse the style of a previous curve', 
                            <<EOH, CurveStyleFactory::CurveStyleGroup)
After using this command, the next curve will have the same style as the 
curve whose name was given as the first argument (it is the name given to 
the `/id=` option to plot.
EOH
end

    # Now, we document some aspects of the above created commands
    c = Commands::Command

    c.document_command("color-map", <<EOD)
Sets the color map for the subsequent curves, until cancelled by an
@auto@ argument.

Color maps are used for 3D plots, ie under the effet of 
{command: contour}, {command: xyz-map} and {command: xy-parametric}. 
EOD

    c.document_command("contour-conrec", <<EOD)
If on, the subsequent curves will use the CONREC algorithm for
contouring. In the opposite case, the contouring algorithm of Gri is
used.

Only useful when {command: contour} is in effect.
EOD

    c.document_command("split-on-nan", <<EOD)
In general, the NaN (not a number, ie invalid data points in the
dataset) in a dataset are silently ignored. When this option is on,
the lines of {command: xy-plot}-style plots are split upon
encountering a NaN.
EOD

    c.document_command("zaxis", <<EOD)
Sets the name of the zaxis for the subsequent curves. This must be an
axis that has been previously created using {command: new-zaxis}. 

This axis will be used to display the colormaps of the following
curve. 
EOD

  end
end

