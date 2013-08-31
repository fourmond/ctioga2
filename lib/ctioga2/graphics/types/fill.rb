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

        # The type of closing: :top, :bottom, :left, :right, :x, :y or
        # :none
        #
        # @todo implement :xy
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

        # Closes the current path according to the current style, based on:
        #  * _bounds_, the boundaries of the plot
        #  * _first_, the first point ([x, y])
        #  * _last_, the last point
        def close_path(t, bounds, first, last)
          tp = @type
          target = @value
          case tp
          when :none
            raise "Close the path !"
          when :bottom, :top
            target = bounds.send(tp)
            tp = :y
          when :left, :right
            target = bounds.send(tp)
            tp = :x
          end

          case tp
          when :x
            t.append_point_to_path(target, last[1])
            t.append_point_to_path(target, first[1])
            t.close_path
          when :y
            t.append_point_to_path(last[0], target)
            t.append_point_to_path(first[0], target)
            t.close_path
          when :close
            t.close_path
          else
            raise "Should not be here"
          end
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

