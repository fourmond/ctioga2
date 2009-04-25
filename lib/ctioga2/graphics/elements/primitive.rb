# primitive.rb: direct use of graphics primitives for tioga
# copyright (c) 2006, 2007, 2008, 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details (in the COPYING file).


require 'ctioga2/utils'
require 'ctioga2/log'

require 'ctioga2/graphics/types'
require 'shellwords'

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision: 948 $', '$Date: 2009-04-17 00:41:44 +0200 (Fri, 17 Apr 2009) $')

  module Graphics

    module Elements
      
      # A TiogaElement that represents a graphics primitive.
      class TiogaPrimitiveCall < TiogaElement
        
        # Some kind of reimplementation of Command for graphics
        # primitives
        class TiogaPrimitive

          # A name (not very useful, but, well, we never know)
          attr_accessor :name

          # An array of compulsory arguments (type specifications)
          attr_accessor :compulsory_arguments
          
          # A hash of optional arguments
          attr_accessor :optional_arguments
          
          # A block that will receive a FigureMaker object, the
          # compulsory arguments and a hash containing optional ones.
          attr_accessor :funcall

          # Creates a TiogaPrimitive object
          def initialize(name, comp, opts = {}, &code)
            @name = name
            @compulsory_arguments = comp
            @optional_arguments = opts
            @funcall = code
          end
        end

        # A TiogaPrimitive object describing the current primitive
        attr_accessor :primitive
        
        # An array containing the values of the compulsory arguments
        attr_accessor :arguments

        # A hash containing the values of the optional arguments
        attr_accessor :options


        # Creates a new TiogaPrimitiveCall object.
        def initialize(primitive, arguments, options)
          @primitive = primitive
          @arguments = arguments
          @options = options
        end

        @known_primitives = {}

        PrimitiveCommands = {}

        PrimitiveGroup = CmdGroup.new("Graphics primitives",
                                      "Graphics primitives", 3)

        # Creates a new primitive with the given parameters, and makes
        # it immediately available as a command.
        def self.primitive(name, long_name, comp, opts = {}, &code)
          primitive = TiogaPrimitive.new(name, comp, opts, &code)
          @known_primitives[name] = primitive
          
          # Now, create the command
          cmd_args = comp.map do |x|
            CmdArg.new(x)
          end

          cmd_opts = {}
          for k,v in opts
            cmd_opts[k] = CmdArg.new(v)
          end
          
          cmd = Cmd.new("draw-#{name}",nil,"--draw-#{name}", 
                        cmd_args, cmd_opts) do |plotmaker, *rest|
            options = rest.pop
            call = Elements::
              TiogaPrimitiveCall.new(primitive,
                                     rest, options)
            plotmaker.root_object.current_plot.
              add_element(call)
          end
          cmd.describe("Draws #{long_name}",
                       "Directly draws #{long_name} on the current plot", PrimitiveGroup)

          PrimitiveCommands[name] = cmd
        end


        # Returns a pair primitive/primitive command for the named
        # primitive, or [ _nil_, _nil_ ]
        def self.get_primitive(name)
          return [@known_primitives[name], PrimitiveCommands[name]]
        end

        # Now, a list of primitives, along with their code.

        primitive("text", "text", [ :point, :string ],
                  {
                    'color' => ColorTypeSpec,
                    'scale' => :float,
                    'angle' => :float,
                    'justification' => :tioga_justification,
                    'alignment' => :tioga_align,
                  }
                  ) do |t, point, string, options|
          # TODO: add a way to specify fonts ???
          options ||= {}
          options['text'] = string
          options['at'] = point.to_figure_xy(t)
          t.show_text(options)
        end

        # TODO: add rendering mode !!
        MarkerOptions = {
          'color' => ColorTypeSpec,
          'stroke_color' => ColorTypeSpec,
          'fill_color' => ColorTypeSpec,
          'scale' => :float,
          'horizontal_scale' => :float,
          'vertical_scale' => :float,
          'angle' => :float,
          'justification' => :tioga_justification,
          'alignment' => :tioga_align,
        }

        primitive("marker", "marker", [ :point, MarkerSpec ],
                  MarkerOptions) do |t, point, marker, options|
          # TODO: add a way to specify fonts ???
          options ||= {}
          options['marker'] = marker
          options['at'] = point.to_figure_xy(t)
          t.show_marker(options)
        end

        primitive("string-marker", "marker", [ :point, :string ],
                  {'font' => :integer }.update(MarkerOptions)
                  ) do |t, point, string, options|
          # TODO: add a way to specify fonts ???
          options ||= {}
          options['text'] = string
          options['at'] = point.to_figure_xy(t)
          t.show_marker(options)
        end

        primitive("arrow", "arrow", [ :point, :point ],
                  {
                    'color' => ColorTypeSpec,
                    'head_scale' => :float,
                    'head_marker' => MarkerSpec,
                    'head_color' => ColorTypeSpec,
                    'tail_scale' => :float,
                    'tail_marker' => MarkerSpec,
                    'tail_color' => ColorTypeSpec,
                    'line_width' => :float,
                    'line_style' => LineStyleSpec,
                  }
                  ) do |t, tail,head, options|
          # TODO: add a way to specify fonts ???
          options ||= {}
          options['head'] = head.to_figure_xy(t)
          options['tail'] = tail.to_figure_xy(t)
          t.show_arrow(options)
        end

        primitive("line", "line", [ :point, :point ],
                  {
                    'color' => ColorTypeSpec,
                    'line_width' => :float,
                    'line_style' => LineStyleSpec,
                  }
                  ) do |t, tail,head, options|
          # TODO: add a way to specify fonts ???
          options ||= {}
          for a in ['head', 'tail'] 
            options["#{a}_marker"] = "None"
          end
          options['head'] = head.to_figure_xy(t)
          options['tail'] = tail.to_figure_xy(t)
          t.show_arrow(options)
        end


        protected

        # Draws the primitive
        def real_do(t)
          args = @arguments + [@options]
          primitive.funcall.call(t, *args)
        end


        # An emulation of the old ctioga behavior
        CmdDraw = Cmd.new('draw', nil, '--draw',
                          [CmdArg.new(:string)]) do |plotmaker, spec|
          spec =~ /^([^:]+):(.*)/
          name = $1
          args = Shellwords.shellwords($2)
          primitive, cmd = TiogaPrimitiveCall.get_primitive(name)
          if primitive
            # We build the arguments based on the number of compulsory ones
            comp = args.slice!(0,primitive.compulsory_arguments.size)
            opts = {}
            for a in args
              if a =~ /^\s*([^=]+)=(.*)/
                opts[$1] = $2
              else
                plotmaker.error "Argument found where a option= was expected: #{a}"
              end
            end
            plotmaker.interpreter.run_command(cmd, comp, opts)
          else
            plotmaker.error "Unkown graphics primitive: #{name}"
          end
        end
        CmdDraw.describe("Draws graphics primitives",
                         <<EOH, PrimitiveGroup)
Tries to emulate the old --draw behavior of ctioga. Don't use it for new things.
EOH
      
      
      end
    end
  end
end
