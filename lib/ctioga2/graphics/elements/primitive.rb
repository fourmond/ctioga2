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
require 'ctioga2/graphics/styles'
require 'shellwords'

# This module contains all the classes used by ctioga
module CTioga2

  module Graphics

    module Elements
      
      # A TiogaElement that represents a graphics primitive.
      #
      # @todo Most of the objects here should rely on getting a
      # BasicStyle object from the options hash and use it to
      # draw. There is no need to make cumbersome and hard to extend
      # hashes.
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

          # The underlying nameless class
          attr_accessor :primitive_class

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

        # The last curve's style... 
        attr_accessor :last_curve_style


        # Creates a new TiogaPrimitiveCall object.
        def initialize(primitive, arguments, options)
          @primitive = primitive
          @arguments = arguments
          @options = options
        end

        undef :clipped, :clipped=

        def clipped
          if @options.key? 'clipped'
            return @options['clipped']
          else
            return true         # Defaults to clipped
          end
        end

        undef :depth, :depth=
          
        def depth
          @options['depth'] || 50
        end

        @known_primitives = {}

        PrimitiveCommands = {}

        PrimitiveGroup = CmdGroup.new('tioga-primitives',
                                      "Graphics primitives",
                                      "Tioga graphics primitives", 3)

        # Creates a new primitive with the given parameters, and makes
        # it immediately available as a command.
        def self.primitive(name, long_name, comp, opts = {}, 
                           desc = nil, &code)
          primitive = TiogaPrimitive.new(name, comp, opts, &code)
          @known_primitives[name] = primitive

          primitive_class = Class.new(TiogaPrimitiveCall)
          primitive.primitive_class = primitive_class
          
          # Now, create the command
          cmd_args = comp.map do |x|
            if x.is_a? CmdArg
              x
            else
              CmdArg.new(x)
            end
          end

          cmd_opts = {}
          for k,v in opts
            cmd_opts[k] = if v.is_a? CmdArg
                            v
                          else
                            CmdArg.new(v)
                          end
          end

          cmd_opts['clipped'] = CmdArg.new('boolean')
          cmd_opts['depth'] = CmdArg.new('integer')
          cmd_opts.merge!(TiogaElement::StyleBaseOptions)

          cmd = Cmd.new("draw-#{name}",nil,"--draw-#{name}", 
                        cmd_args, cmd_opts) do |plotmaker, *rest|
            options = rest.pop
            call = primitive_class.new(primitive,
                                     rest, options)
            container = plotmaker.root_object.current_plot
            call.setup_style(container, options)
            call.last_curve_style = plotmaker.curve_style_stack.last
            container.add_element(call)
          end
          if ! desc
            desc = "Directly draws #{long_name} on the current plot"
          end
          cmd.describe("Draws #{long_name}",
                       desc, 
                       PrimitiveGroup)

          PrimitiveCommands[name] = cmd
          return primitive_class
        end

        # This creates a primitive base on a style object, given a
        # _style_class_, the base _style_name_ for the underlying
        # styling system, options to remove and options to add.
        #
        # The underlying code receives:
        # * the FigureMaker object
        # * the compulsory arguments
        # * the style
        # * the raw options
        def self.styled_primitive(name, long_name, comp, style_class, 
                                  style_name, without = [],
                                  additional_options = {},
                                  set_style_command = nil,
                                  &code)
          options = style_class.options_hash.without(without)
          options.merge!(additional_options)

          set_style_command ||= style_name
          desc = <<"EOD"
Draws #{long_name} on the current plot, using the given style.
For more information on the available options, see the 
{command: define-#{set_style_command}-style} command.
EOD

          cls = self.primitive(name, long_name, comp, options, desc) do |*all|
            opts = all.pop
            style = get_style()
            style.set_from_hash(opts)
            all << style << opts
            code.call(*all)
          end
          cls.define_style(set_style_command, style_class)
          return cls
        end


        # Returns a pair primitive/primitive command for the named
        # primitive, or [ _nil_, _nil_ ]
        def self.get_primitive(name)
          return [@known_primitives[name], PrimitiveCommands[name]]
        end

        # Now, a list of primitives, along with their code.

        styled_primitive("text", "text", 
                         [ 'point', 'text' ],
                         Styles::FullTextStyle,
                         'text',
                         ['text'],
                         {'font' => 'latex-font'}
                  ) do |t, point, string, style, options|
          # @todo add a way to specify fonts ???
          options ||= {}
          if options['font']
            string = options['font'].fontify(string)
          end
          style.draw_text(t, string, *(point.to_figure_xy(t)))
        end

        styled_primitive("marker", "marker", 
                         [ 'point', 'marker' ],
                         Styles::MarkerStringStyle,
                         'marker',
                         ['font'] # font doesn't make any sense with a
                         # marker spec
                         ) do |t, point, marker, style, options|
          style.draw_marker(t, marker, *point.to_figure_xy(t))
        end

        styled_primitive("string-marker", "marker", 
                         [ 'point', 'text' ],
                         Styles::MarkerStringStyle,
                         'marker-string', [],
                         {},
                         'marker'
                         ) do |t, point, string, style, options|
          style.draw_string_marker(t, string, *point.to_figure_xy(t))
        end


        styled_primitive("arrow", "arrow", 
                         [ 'point', 'point' ], 
                         Styles::ArrowStyle,
                         'arrow') do |t, tail, head, style, options|
          stl = style.dup
          stl.use_defaults_from(Styles::ArrowStyle::TiogaDefaults)
          stl.draw_arrow(t, *( tail.to_figure_xy(t) + 
                               head.to_figure_xy(t) ))
        end

        styled_primitive("line", "line", 
                         [ 'point', 'point' ],
                         Styles::ArrowStyle,
                         'line'
                  ) do |t, tail, head, style, options|
          style.draw_arrow(t, *( tail.to_figure_xy(t) + 
                                 head.to_figure_xy(t) ))
        end

        # @todo Do the same thing for arrows...
        styled_primitive("oriented-line", "oriented-line", 
                         [ 'point', 'dimension' ],
                         Styles::OrientedLineStyle,
                         'oriented-line'
                        ) do |t, org, dim, style, options|
          
          style.draw_oriented_arrow(t, *(org.to_figure_xy(t) + [dim]))
        end


        styled_primitive("image", "image", 
                         [ CmdArg.new('text', 'file'), 
                           CmdArg.new('point', 'top-left'), 
                           CmdArg.new('point', 'bottom-right')
                         ], 
                         Styles::ImageStyle,
                         'image') do |t, file, tl, br, style, options|
          style.draw_image(t, file, tl, br)
        end

        # Here, we need to add deprecated options for backward
        # compatibility

        for cmd in ['draw-line', 'draw-arrow']
          Commands::make_alias_for_option cmd, 'width', 'line_width', true
          Commands::make_alias_for_option cmd, 'style', 'line_style', true
        end

        styled_primitive("box", "box", 
                         [ 'point', 'point' ], 
                         Styles::BoxStyle,
                         'box') do |t, tl, br, style, options|
          x1,y1 = tl.to_figure_xy(t)
          x2,y2 = br.to_figure_xy(t)
          style.draw_box(t, x1, y1, x2, y2)
        end


        Commands::make_alias_for_option 'draw-box', 'fill_color', 'fill-color'
        Commands::make_alias_for_option 'draw-box', 'fill_transparency', 'fill-transparency'

        protected

        # Draws the primitive
        def real_do(t)
          args = @arguments + [@options]
          ## @todo this is a really ugly hack for passing
          ## last_curve_style around
          $last_curve_style = @last_curve_style
          instance_exec(t, *args, &primitive.funcall)
        end
        
        DrawingSpecType = 
          CmdType.new('drawing-spec', :string, <<EOD)
A ctioga 1 --draw specification.
EOD


        # An emulation of the old ctioga behavior
        CmdDraw = Cmd.new('draw', nil, '--draw',
                          [CmdArg.new('drawing-spec')]) do |plotmaker, spec|
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
                plotmaker.error { "Argument found where a option= was expected: #{a}" }
              end
            end
            plotmaker.interpreter.run_command(cmd, comp, opts)
          else
            plotmaker.error { "Unkown graphics primitive: #{name}" }
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
