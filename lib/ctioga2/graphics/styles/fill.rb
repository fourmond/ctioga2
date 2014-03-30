# fill.rb: fill styles
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
require 'ctioga2/log'

require 'ctioga2/graphics/geometry'
require 'ctioga2/graphics/types/dimensions'

# This module contains all the classes used by ctioga
module CTioga2

  module Graphics

    # All the styles
    module Styles


      # This class handles drawing the pattern in a fill.
      #
      # It is a base class.
      class FillPattern

        # Draws the pattern over the whole output, with primary color
        # _color_ and secondary color _secondary_ (not implemented
        # yet).
        #
        # This does nothing. Derived classes do the job
        def do(t, color, secondary = nil)
        end

        def self.from_text(str)
          els = str.split(/\s*:\s*/)
          args = []
          if els.size > 1
            args = els[1].split(/\s*,\s*/)
          end
          
          case els[0]
          when /^hlines$/
            return SingleLineFillPattern.new(0, *args)
          when /^vlines$/
            return SingleLineFillPattern.new(90, *args)
          when /^lines$/
            return SingleLineFillPattern.new(*args)
          when /^xlines$/
            return CrossedLinesFillPattern.new(*args)
          end
        end
      end

      FillPatternType = 
        CmdType.new('fill-pattern', { 
                      :type => :function_based,
                      :class => Graphics::Styles::FillPattern
                    })

      # @
      class SingleLineFillPattern

        # Line width (in line widths units ?)
        attr_accessor :line_width

        # Separation between the lines, a dimension
        attr_accessor :distance

        # Angle of the lines
        attr_accessor :angle

        def initialize(an = 0,dst = nil, lw = nil)
          @distance = if dst
                        if dst.is_a? Types::Dimension
                          dst
                        else
                          Types::Dimension::from_text(dst, :x, :bp)
                        end
                      else
                        Types::Dimension.new(:bp, 5)
                      end
          @line_width = lw ? lw.to_f : 0.8
          @angle = an.to_f
        end

        def do(t, color, secondary = nil)
          # Secondary is not used

          t.context do
            t.stroke_color = color
            t.line_width = @line_width
            # Make figure coordinates page coordinates
            t.set_bounds([t.convert_frame_to_page_x(0),
                          t.convert_frame_to_page_x(1),
                          t.convert_frame_to_page_y(1),
                          t.convert_frame_to_page_y(0)])

            # Now we can work
            dx = -@distance.to_figure(t, :x) * 
              Math.sin(Math::PI/180 * @angle)
            dy = @distance.to_figure(t, :y) * 
              Math.cos(Math::PI/180 * @angle)

            if dy < 0
              dy = -dy
              dx = -dx
            end

            if dx.abs < 1e-12          # Horizontal lines
              y = 0
              while y <= 1
                t.stroke_line(0, y, 1, y)
                y += dy
              end
            elsif dy.abs < 1e-12
              x = 0
              dx = dx.abs
              while x <= 1
                t.stroke_line(x, 0, x, 1)
                x += dx
              end
            else
              if dx > 0
                line = Line.new(0, 0, dy, -dx)
              else
                line = Line.new(1, 0, dy, -dx)
              end
              segs = [ Segment.new(0,0,1,0), Segment.new(1,0,1,1),
                       Segment.new(1,1,0,1), Segment.new(0,1,0,0)]
              while true
                ints = []
                for s in segs
                  v = s.intersection(line)
                  ints << v if v 
                end
                if ints.size == 0
                  break
                elsif ints.size == 2
                  t.stroke_line(ints[0][0], ints[0][1],
                                ints[1][0], ints[1][1])
                elsif ints.size == 3
                  # Rare case but must be handled anyway
                  if ints[0][0] == ints[1][0]
                    ints.shift
                  end
                  t.stroke_line(ints[0][0], ints[0][1],
                                ints[1][0], ints[1][1])
                end
                line.x += dx
                line.y += dy
              end
            end
          end
          
        end
      end


      class CrossedLinesFillPattern

        def initialize(dst1 = nil, lw1 = nil, angle = 45, 
                       dst2 = nil, lw2 = nil, dangle = 90)
          @first = SingleLineFillPattern.new(angle, dst1, lw1)
          @second = SingleLineFillPattern.new(@first.angle + dangle.to_f, 
                                              dst2 || dst1, lw2 || lw1)
        end


        def do(t, color, secondary = nil)
          @first.do(t, color)
          @second.do(t, secondary || color)
        end
      end

      # A style that handles drawing a fill.
      #
      # \todo add ways to specify complex fills, such as patterned
      # fills and so on. Those would use clipping the path and base
      # themselves on the coordinates of the current frame -- or more
      # nicely use dimensions ? (which would allow to mix both to some
      # extent ?)
      #
      # \todo more attributes ?
      #
      # @todo This class should also provide image-based fills, with
      # CSS-like capacities (scaling, tiling, centering, and so on...)
      class FillStyle < BasicStyle

        # The color.
        typed_attribute :color, "color"

        # The transparency
        typed_attribute :transparency, 'float'

        # The fill pattern
        typed_attribute :pattern, "fill-pattern"

        # Sets up the parameters for the fill. Must be called before
        # any path drawing.
        #
        # \warning You *must* call FillStyle#do_fill for
        # filling. Directly calling FigureMaker#fill is not a good
        # idea, as you lose all 'hand-crafted' fills !
        def setup_fill(t)
          if ! @pattern
            t.fill_color = @color if @color
            t.fill_transparency = @transparency if @transparency
          end
        end

        # Does the actual filling step. Must be used within a context,
        # as it quite messes up with many things. Must be called after
        # a call to #setup_fill.
        def do_fill(t)
          if @pattern  && @color
            t.clip
            @pattern.do(t, @color)
          else
            t.fill
          end
        end

      end

      # Same as FillStyle, but with additional parameters that handle
      # how the fill should be applied to curves.
      class CurveFillStyle < FillStyle

        typed_attribute :close_type, 'fill-until'
        
      end

    end
  end
end

