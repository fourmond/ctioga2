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

        GridBoxRE = /^\s*grid:(\d+)\s*,\s*(\d+)(?:,(#{OptionHashRE}+))?\s*$/

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

        def self.from_text(txt)
          if txt =~ GridBoxRE
            return GridBox.new(GridLayout.current_grid, $1.to_i, $2.to_i, 
                               $3) # The latter being to remove
                                          # the initial comma
          else
            raise "#{txt} is not a grid box."
          end
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
          @x = x.to_i
          @grid = grid
          @y = y.to_i
          @overrides = options || {}
        end

        def to_frame_coordinates(t)
          a = @grid.frame_coordinates(t, @x, @y)
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

        def initialize(nup = "2x2")
          if nup.respond_to?(:split)
            if nup =~ /,/
              @hscales, @vscales = nup.split(/\s*x\s*/).map { |x| 
                x.split(/\s*,\s*/).map { |y| y.to_f }
              }
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
        end

        # The grid currently in use.
        @current_grid = nil
        
        def self.current_grid=(grid)
          @current_grid = grid
        end

        def self.current_grid
          return @current_grid
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
