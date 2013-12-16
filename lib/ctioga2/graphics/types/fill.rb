# fill.rb: fill-related types
# copyright (c) 2013 by Vincent Fourmond
  
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

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Types

      # This class provides a way to close a path in order to fill a
      # curve.
      class FillUntil 

        # The type of closing: :top, :bottom, :left, :right, :x, :y,
        # :close, :xy or :none
        attr_accessor :type
        
        # An accessory value (when necessary)
        attr_accessor :value

        # Builds from text
        def self.from_text(str)
          ret = FillUntil.new
          case str
          when /^\s*(left|right|top|bottom)\s*$/
            ret.type = $1.downcase.to_sym
          when /^\s*axis|xaxis\s*$/
            ret.type = :y
            ret.value = 0
          when /^\s*yaxis\s*$/
            ret.type = :x
            ret.value = 0
          when /^\s*(x|y)\s*[:=]\s*(.*)$/
            ret.type = $1.downcase.to_sym
            ret.value = $2.to_f
          when /^\s*close\s*$/
            ret.type = :close
          when /^\s*xy\s*[:=]\s*(.*)$/
            ret.type = :xy
            ret.value = Point.from_text($1)
          else
            ret.type = :y
            ret.value = str.to_f
          end

          return ret
        end

        # If there is actually a closing
        def fill?
          return @type != :none
        end

        # Wether we are closing by a vertical line
        def vertical?
          return (@type == :x || @type == :left || @type = :right)
        end

        # Wether we are closing with a horizontal line
        def horizontal?
          return (@type == :y || @type == :bottom || @type = :top)
        end

        # Returns the effective value of the 
        def effective_value(bounds)
          case @type
          when :bottom, :top
            return bounds.send(@type)
          when :left, :right
            return bounds.send(@type)
          else
            return @value
          end
        end

        # Closes the current path according to the current style, based on:
        #  * _bounds_, the boundaries of the plot
        #  * _first_, the first point ([x, y])
        #  * _last_, the last point
        def close_path(t, bounds, first, last)
          tp = @type
          target = effective_value(bounds)

          case tp
          when :none
            raise "Close the path !"
          when :x, :left, :right
            t.append_point_to_path(target, last[1])
            t.append_point_to_path(target, first[1])
          when :y, :bottom, :top
            t.append_point_to_path(last[0], target)
            t.append_point_to_path(first[0], target)
          when :xy
            t.append_point_to_path(* target.to_figure_xy(t))
          when :close
          else
            raise "Should not be here"
          end
          t.close_path
        end

      end

      # Something meant to be fed to PlotStyle#get_axis_style
      FillType = 
        CmdType.new('fill-until', { :type => :function_based,
                      :class => Graphics::Types::FillUntil
                                 }, <<EOD)
How to close the path of a curve to fill it. Can be:
 * @bottom@, @top@, @left@, @right@ to fill until the named side of the
   plot
 * @axis@ or @xaxis@ to fill until the X axis (ie y = 0)
 * @yaxis@ to fill until the Y axis (ie x = 0)
 * @x:value@ or @x=value@ to fill until the given X value
 * @y:value@ or @y=value@ to fill until the given Y value
 * @close@ for just closing the path (doesn't look good in general)
 * @none@ for no fill
EOD


      
    end
  end
end

