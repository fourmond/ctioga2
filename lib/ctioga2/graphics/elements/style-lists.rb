# style-lists.rb: drawing of lists of style elements (colors)
# copyright (c) 2014 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details (in the COPYING file).


require 'ctioga2/graphics/elements/primitive'

# This module contains all the classes used by ctioga
module CTioga2

  module Graphics

    module Elements

      module StyleLists

        ListCommonOptions = {
          'columns'   => 'integer',
          'padding' => 'dimension',
          'scale' => 'float'
        }.update(TiogaPrimitiveCall::ArrowOptions)
      


        TiogaPrimitiveCall.
          primitive("color-list", 
                    "the list of all named colors", 
                    [ 'point', 'dimension' ],
                    ListCommonOptions) do |t, point, width, options|

          cols = options['columns'] || 3

          ox, oy = point.to_figure_xy(t)

          # There's going to be a lot of common code here
          padding = options['padding'] || 
            Types::Dimension.from_text("5bp", :x)
          pad_dx = padding.to_figure(t, :x)
          col_dx = width.to_figure(t, :x)/cols
          col_w = col_dx - pad_dx * (cols - 1)/cols
          

          # Colors by alphabetic name...
          colors = Tioga::ColorConstants::constants.sort
          l = 0
          cc = 0

          scale = options['scale'] || 0.8

          txt_dy = -Types::Dimension::from_text("1.2dy", :y).to_figure(t, :y) * scale
          box_dy = -Types::Dimension::from_text("1.1dy", :y).to_figure(t, :y)

          tdy = txt_dy + box_dy

          p colors
          for c in colors
            color = Tioga::ColorConstants::const_get(c)
            
            xb = ox + cc * col_dx 
            yt = oy + l * tdy
            p 
            ym = yt + txt_dy
            t.show_text({
                          'x' => xb + 0.5 * col_dx,
                          'y' => 0.8*ym +0.2*yt,
                          'text' => c.to_s,
                          'scale' => scale
                        })

            t.fill_color = color
            t.append_rect_to_path(xb + 0.5 * pad_dx,
                                  ym, col_w, box_dy)
            t.fill_and_stroke


            cc += 1
            if cc >= cols
              cc = 0
              l += 1
            end
          end
          
          
        end
      end
      
    end
  end
end
