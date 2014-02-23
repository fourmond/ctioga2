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

          t.context do 
            for c in colors
              color = Tioga::ColorConstants::const_get(c)
              
              xb = ox + cc * col_dx 
              yt = oy + l * tdy
              ym = yt + txt_dy
              t.show_text({
                            'x' => xb + 0.5 * col_dx,
                            'y' => 0.8*ym +0.2*yt,
                            'text' => c.to_s,
                            'scale' => scale
                          })
              
              t.fill_color = color
              t.line_width = 0.7
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

        TiogaPrimitiveCall.
          primitive("marker-list", 
                    "the list of all named markers", 
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
          colors = Tioga::MarkerConstants::constants.sort
          l = 0
          cc = 0

          scale = options['scale'] || 0.8

          dy = -Types::Dimension::from_text("1.3dy", :y).to_figure(t, :y) * scale

          m_dx = Types::Dimension::from_text("1.2dy", :x).to_figure(t, :x) * scale

          for c in colors
            mk = Tioga::MarkerConstants::const_get(c)
            next unless mk.is_a? Array
            
            xb = ox + cc * col_dx 
            yt = oy + (l+0.5) * dy
            t.show_text({
                          'x' => xb + m_dx,
                          'y' => yt,
                          'text' => c.to_s,
                          'scale' => scale,
                          'justification' => Tioga::FigureConstants::LEFT_JUSTIFIED,
                          'alignment' => Tioga::FigureConstants::ALIGNED_AT_MIDHEIGHT
                        })

            t.show_marker({
                            'x' => xb + m_dx*0.5,
                            'y' => yt,
                            'marker' => mk,
                            'scale' => scale * 1.1,
                            'alignment' => Tioga::FigureConstants::ALIGNED_AT_MIDHEIGHT
                          })
                            
            cc += 1
            if cc >= cols
              cc = 0
              l += 1
            end
          end
        end


        TiogaPrimitiveCall.
          primitive("line-style-list", 
                    "the list of all named line styles", 
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
          colors = Graphics::LineStyles::constants.sort
          colors -= Tioga::FigureConstants::constants
          l = 0
          cc = 0

          scale = options['scale'] || 0.8

          txt_dy = -Types::Dimension::from_text("1.2dy", :y).to_figure(t, :y) * scale
          box_dy = -Types::Dimension::from_text("1.1dy", :y).to_figure(t, :y)

          tdy = txt_dy + box_dy

          for c in colors
            color = Graphics::LineStyles::const_get(c)
            next unless color.is_a? Array
            
            xb = ox + cc * col_dx 
            yt = oy + l * tdy
            ym = yt + txt_dy
            t.show_text({
                          'x' => xb + 0.5 * col_dx,
                          'y' => 0.8*ym +0.2*yt,
                          'text' => c.to_s.gsub(/_/, '\_'),
                          'scale' => scale
                        })

            t.context do 
              t.line_type = color
              t.move_to_point(xb + 1.5 * pad_dx,
                                     ym+box_dy*0.5)
              t.append_point_to_path(xb +col_dx- 1.5 * pad_dx,
                                     ym+box_dy*0.5)
              t.stroke
            end


            cc += 1
            if cc >= cols
              cc = 0
              l += 1
            end
          end
        end


        SetOptions = {
          'scale' => 'float'
        }

        # Now, a list of color sets
        TiogaPrimitiveCall.
          primitive("color-set-list", 
                    "the list of all color sets", 
                    [ 'point', 'dimension' ], 
                    SetOptions) do |t, point, width, options|

          ox, oy = point.to_figure_xy(t)

          col_dx = width.to_figure(t, :x)
          

          
          scale = options['scale'] || 0.8
          txt_dy = -Types::Dimension::from_text("1.3dy", :y).to_figure(t, :y) * scale
          box_dy = -Types::Dimension::from_text("1.1dy", :y).to_figure(t, :y)

          tdy = txt_dy + box_dy

          sets = Styles::CurveStyleFactory::parameters['line_color'].sets
          
          set_names = sets.keys.sort

          xl = ox
          yt = oy

          p_dx = Types::Dimension::from_text("2bp", :x).to_figure(t, :x)

          for s in set_names
            cs = sets[s]
            ym = yt + txt_dy
            nb = cs.size
            t.show_text({
                          'x' => xl + 0.5 * col_dx,
                          'y' => 0.7*ym +0.3*yt,
                          'text' => "\\texttt{#{s}}: #{nb} colors",
                          'scale' => scale
                        })

            dx = col_dx/nb
            
            idx = 0
            t.context do
              for c in cs
                t.fill_color = c
                t.line_width = 0.7
                t.append_rect_to_path(xl + 0.5 * p_dx + idx * dx,
                                      ym, dx - p_dx, box_dy)
                t.fill_and_stroke
                idx += 1
              end
            end
            
            yt += tdy
          end
        end

        # Now, a list of color sets
        TiogaPrimitiveCall.
          primitive("marker-set-list", 
                    "the list of all marker sets", 
                    [ 'point', 'dimension' ], SetOptions
                    ) do |t, point, width, options|

          ox, oy = point.to_figure_xy(t)
          col_dx = width.to_figure(t, :x)
          

          
          scale = options['scale'] || 0.8
          txt_dy = -Types::Dimension::from_text("1.3dy", :y).to_figure(t, :y) * scale
          box_dy = -Types::Dimension::from_text("1.1dy", :y).to_figure(t, :y)

          tdy = txt_dy + box_dy

          sets = Styles::CurveStyleFactory::parameters['marker_marker'].sets
          
          set_names = sets.keys.sort

          xl = ox
          yt = oy

          p_dx = Types::Dimension::from_text("2bp", :x).to_figure(t, :x)

          mdx = Types::Dimension::from_text("1.1dy", :x).to_figure(t, :x)

          for s in set_names
            cs = sets[s]
            ym = yt + txt_dy
            nb = cs.size
            t.show_text({
                          'x' => xl + 0.5 * col_dx,
                          'y' => 0.7*ym +0.3*yt,
                          'text' => "\\texttt{#{s}}: #{nb} markers",
                          'scale' => scale
                        })

            dx = col_dx/nb
            
            idx = 0
            for c in cs
              t.show_marker({
                              'x' => xl + mdx * (idx + 0.5),
                              'y' => ym,
                              'marker' => c,
                              'scale' => scale * 1.1,
                              'alignment' => Tioga::FigureConstants::ALIGNED_AT_TOP
                            })

              idx += 1
            end
            
            yt += tdy
          end
        end
      
      end
    end
  end
end
