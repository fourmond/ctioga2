# tangent.rb: code for drawing tangents
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details (in the COPYING file).


require 'ctioga2/graphics/elements/primitive'
require 'shellwords'

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Elements

      module Tangents

        TangentOptions = {
          'xfrom'   => 'float',
          'xto'     => 'float',
          'yfrom'   => 'float',
          'yto'     => 'float',
          'xextent' => 'float',
          'yextent' => 'float',
          'nbavg'  =>  'integer'
        }.update(TiogaPrimitiveCall::ArrowOptions)
      
        TiogaPrimitiveCall.
          primitive("tangent", "tangent", [ 'data-point'],
                    TangentOptions) do |t, point,options|
          options ||= {}
          nb = options['nbavg'] || 7
          x = point.x_val(nb)
          y = point.y_val(nb)
          slope = point.slope(nb)

          # Now, we parse the head/tail spec.
          if d = options['xextent']
            options['tail'] = [x, y]
            options['head'] = [x+d, y + d*slope]
          elsif d = options['yextent']
            options['tail'] = [x, y]
            options['head'] = [x+d/slope, y + d]
          elsif options['xfrom'] || options['yfrom'] || 
              options['xto'] || options['yto']
            if xf = options['xfrom']
              options['tail'] = [xf, y - (x - xf)*slope]
            elsif yf = options['yfrom']
              options['tail'] = [x - (y-yf)/slope, yf]
            else
              options['tail'] = [x,y]
            end

            if xt = options['xto']
              options['head'] = [xt, y - (x - xt)*slope]
            elsif yt = options['yto']
              options['head'] = [x - (y-yt)/slope, yt]
            else
              options['head'] = [x,y]
            end
          else
            # We don't bother too much about the head/tail
            options['head'] = [x, y]
            dx = point.dx(nb) * 10
            options['tail'] = [x-dx, y - dx*slope]
            options['line_width'] = 0
            options['tail_marker'] = "None"
          end

          # We look for any color argument:
          if ! (options['color'] || options['tail_color'] || 
                options['head_color'])
            options['color'] = $last_curve_style.line.color
          end
          
          # Now, we delete elements from the hash that don't have
          # anything to do there:
          for k in TangentOptions.keys - 
              TiogaPrimitiveCall::ArrowOptions.keys
            options.delete k
          end
          
          t.show_arrow(options)
        end
      end
      
    end
  end
end
