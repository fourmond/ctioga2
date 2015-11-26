# grib.rb: setup and use of a "graph grid"
# copyright (c) 2009,2010 by Vincent Fourmond
  
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

require 'ctioga2/graphics/types/dimensions'
require 'ctioga2/graphics/types/boxes'

module CTioga2

  module Graphics

    module Types

      # The position of a single element in a GridLayout
      #
      # \todo add the possibility to override one element of the
      # final positions.
      class GridBox < Box

        OptionHashRE = /([\w-]+)\s*=\s*([^,]+),?\s*/

        GridBoxRE = /^\s*grid:(?:(\d+(?:-\d+)?)\s*,\s*(\d+(?:-\d+)?)|(next))(?:,(#{OptionHashRE}+))?\s*$/

        # This hash helps to convert from a hash-based representation
        # of frame coordinates to the array-based one.
        #
        # \todo I should either use existing code or refactor into
        # something globally useful.
        FrameCoordsOverride = { 'xl' => 0,
          'yt' => 1,
          'xr' => 2,
          'yb' => 3
        }

        # The position of the element in the grid (arrays [left,right]
        # or [top, bottom])
        attr_accessor :x,:y

        def self.from_text(txt)
          if txt =~ GridBoxRE
            if $3               # next
              x = 0
              y = 0
              grd = GridLayout.current_grid
              lastel = grd.elements.last
              if lastel
                x = lastel.x.max + 1
                y = lastel.y.max
                if x >= grd.xsize
                  x = 0
                  y += 1
                end
              end
              return GridBox.new(grd, x, y, $4)
            else
              return GridBox.new(GridLayout.current_grid, $1, $2, 
                                 $4) # The latter being to remove
            # the initial comma
            end
          else
            raise "#{txt} is not a grid box."
          end
        end

        def parse_range(str)
          if str.is_a? Array
            return str
          elsif str =~ /(\d+)\s*-\s*(\d+)/
            return [$1.to_i, $2.to_i]
          else
            return [str.to_i, str.to_i]
          end
        end

        # Returns false if the position given by @x and @y are within
        # the grid
        def within_grid?
          if @x.min < 0 || @x.max >= @grid.xsize
            return false
          end
          if @y.min < 0 || @y.max >= @grid.ysize
            return false
          end
          return true
        end
          
        
        def initialize(grid, x, y, options = {})
          if options.is_a? String
            str = options
            options = {}
            str.split(/\s*,\s*/).map { |s|
              s =~ OptionHashRE
              options[$1] = 
              BaseCoordinate.from_text($2,if FrameCoordsOverride[$1] % 2 == 0
                                            :x
                                          else
                                            :y
                                          end, :frame)
            }
          end
          
          @grid = grid
          @x = parse_range(x).sort
          @y = parse_range(y).sort
          @overrides = options || {}

          if ! within_grid?
            raise "Grid element #{x},#{y} is outside grid boundaries (#{@grid.xsize}x#{@grid.ysize})"
          end

          @grid.elements << self
        end

        def to_frame_coordinates(t)
          a = @grid.frame_coordinates(t, @x[0], @y[0])
          ov = @grid.frame_coordinates(t, @x[1], @y[1])
          # Override with the right-bottom element.
          a[2] = ov[2]
          a[3] = ov[3]

          ## \todo write a framework for manipulating this !
          for k,v in @overrides
            next unless FrameCoordsOverride.key?(k)
            a[FrameCoordsOverride[k]] = v.to_frame(t)
          end
          return a
        end
      end

      # This class provides a grid-like layout through the use of a grid
      # setup command and a grid box specification.
      class GridLayout

        # The margins (left, right, top, bottom) around the whole grid
        attr_accessor :outer_margins

        # The X offset to go from the right-hand side of one element to
        # the left-hand-side of the next
        attr_accessor :delta_x

        # The Y offset to go from the bottom of one element to
        # the top of the next.
        attr_accessor :delta_y

        # The nup: an array nb horizontal, nb vertical
        attr_accessor :nup

        # Horizontal scales
        attr_accessor :hscales

        # Vertical scales
        attr_accessor :vscales

        # The GridBox objects we've seen so far
        attr_accessor :elements

        def initialize(nup = "2x2")
          if nup.respond_to?(:split)
            if nup =~ /,/
              @hscales, @vscales = nup.split(/\s*x\s*/).map { |x| 
                x.split(/\s*,\s*/).map { |y| y.to_f }
              }
              if @hscales.size == 1
                @hscales = [1] * @hscales[0].to_i
              elsif @vscales.size == 1
                @vscales = [1] * @vscales[0].to_i
              end
              @nup = [@hscales.size, @vscales.size]
            else
              @nup = nup.split(/\s*x\s*/).map { |s| s.to_i }
            end
          else
            @nup = nup.dup
          end

          # Initialize with the given
          @outer_margins = {
            'left' =>  Dimension.new(:dy, 2.5, :x),
            'right' => Dimension.new(:bp, 6, :x),
            'bottom' =>  Dimension.new(:dy, 2.5, :y),
            'top' => Dimension.new(:dy, 2.5, :y)
          }
          @delta_x = Dimension.new(:dy, 2.5, :x)
          @delta_y = Dimension.new(:dy, 2.5, :y)

          @hscales ||= [1] * @nup[0]
          @vscales ||= [1] * @nup[1]

          @elements = []
        end

        # The grid currently in use.
        @current_grid = nil
        
        def self.current_grid=(grid)
          @current_grid = grid
        end

        def self.current_grid
          return @current_grid
        end

        def xsize
          return @hscales.size
        end

        def ysize
          return @vscales.size
        end

        # Compute the frame coordinates fo the x,y element of the
        # grid. They are numbered from the top,left element.
        def frame_coordinates(t, x, y)
          compute_lengths(t)
          xo = if x > 0
                 @hscales[0..(x-1)].inject(0,:+) * @wbase
               else
                 0
               end
          xl = @outer_margins['left'].to_frame(t, :x) + xo + 
            x * @delta_x.to_frame(t, :x)
          yo = if y > 0
                 @vscales[0..(y-1)].inject(0,:+) * @hbase
               else
                 0
               end
          yt = 1 - (@outer_margins['top'].to_frame(t, :y) + yo +
                    y * @delta_y.to_frame(t, :y))
          return [xl, yt, 
                  xl + @wbase * @hscales[x], 
                  yt - @hbase * @vscales[y]]
        end

        protected 

        # Compute the necessary variables in frame coordinates
        def compute_lengths(t)
          return if (@wbase && @hbase)
          @wbase = (1 - 
            (@outer_margins['left'].to_frame(t, :x) + 
             @outer_margins['right'].to_frame(t, :x) + 
             @delta_x.to_frame(t, :x) * (@nup[0]-1)))/@hscales.inject(0,:+)
          @hbase = (1 - 
            (@outer_margins['top'].to_frame(t, :y) + 
             @outer_margins['bottom'].to_frame(t, :y) + 
             @delta_y.to_frame(t, :y) * (@nup[1]-1)))/@vscales.inject(0,:+)
        end

      end

    end
  end

end
