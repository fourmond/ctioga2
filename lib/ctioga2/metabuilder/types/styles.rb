# styles.rb : Different Types to deal with various style arguments.
# Copyright (C) 2006, 2009 Vincent Fourmond
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA


require 'ctioga2/utils'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module MetaBuilder
    module Types

      # A color for use with Tioga, ie a [red, green, blue] array of
      # values between 0 and 1.0. It accepts HTML-like colors, or
      # three comma-separated values between 0 and 1.
      class TiogaColorType < Type
        
        type_name :tioga_color, 'color'

        HLSRegexp = /(?:hls):/i

        def parse_one_color(str)
          if str =~ HLSRegexp
            hls = true
            str = str.gsub(HLSRegexp,'')
          else
            hls = false
          end
          if str =~ /^\s*#([0-9a-fA-F]{6})\s*$/
            value =  $1.scan(/../).map {
              |i| i.to_i(16)/255.0 
            }
          elsif str =~ /^\s*#([0-9a-fA-F]{3})\s*$/
            value =  $1.scan(/./).map {
              |i| i.to_i(16)/15.0 
            }
          else
            begin 
              if Tioga::ColorConstants::const_defined?(str)
                value = Tioga::ColorConstants::const_get(str)
                return value
              end
            rescue
            end
            value = str.split(/\s*,\s*/).map do |s|
              s.to_f
            end
          end
          if value.size != 3
            raise IncorrectInput, "You need exactly three values to make up a color"
          end
          if hls
            # Requires Tioga r599
            value = Tioga::FigureMaker.hls_to_rgb(value)
          end
          return value
        end

        def string_to_type_internal(str)
          # We implement a xcolor-like color mix stuff
          elems = str.split(/!(\d+(?:\.\d+)?)!?/)
          if (elems.size % 2) == 0
            elems << "White"    # Implicit mix with white
          end
          
          temp = parse_one_color(elems.shift)
          
          while elems.size > 0
            frac = elems.shift.to_f/100.0
            new_color = parse_one_color(elems.shift)
            3.times do |i|
              temp[i] = frac * temp[i] + (1 - frac) * new_color[i]
            end
          end

          return temp
        end
      end

      # A line style for Tioga. It will be represented as:
      # 
      #  a,b,c,d,...:e
      #  
      # This creates a line style of:
      # 
      #  [[a,b,c,d,...],e]
      #  
      # If the :e is omitted 0 is used.
      class LineStyleType < Type
        
        type_name :tioga_line_style, 'line_style'
        
        def string_to_type_internal(str)
          specs = str.split(/\s*,\s*/)
          if specs.last =~ /:(.*)$/
            phase = $1.to_f
            specs.last.gsub!(/:.*$/,'')
          else
            phase = 0
          end
          return [ specs.map { |s| s.to_f }, phase]
        end
      end

      # A marker Type for Tioga. Input as
      # 
      #  a,b(,c)?
      #  
      class MarkerType < Type
        
        type_name :tioga_marker, 'marker'
        
        def string_to_type_internal(str)
          specs = str.split(/\s*,\s*/)
          if specs.size == 2
            return [specs[0].to_i, specs[1].to_i]
          elsif specs.size == 3
            return [specs[0].to_i, specs[1].to_i, specs[2].to_f]
          else
            raise IncorrectInput, "You need two or three values to make a marker"
          end
        end
      end

      # The type of edges/axis
      class AxisType < Type

        include Tioga::FigureConstants

        ValidTypes = {
          /hidden|off/i => AXIS_HIDDEN,
          /line/i => AXIS_LINE_ONLY, 
          /ticks/i => AXIS_WITH_TICKS_ONLY,
          /major/i => AXIS_WITH_MAJOR_TICKS_ONLY, 
          /major-num/i => AXIS_WITH_MAJOR_TICKS_AND_NUMERIC_LABELS,
          /full/i => AXIS_WITH_TICKS_AND_NUMERIC_LABELS
        }
        
        type_name :tioga_axis_type, 'axis_type'
        
        def string_to_type_internal(str)
          for k,v in ValidTypes
            if str =~ /^\s*#{k}\s*/
                return v
            end
          end
          raise IncorrectInput, "Not an axis type: #{str}"
        end
      end

      # LaTeX font
      class LaTeXFontBaseType < Type
        type_name :latex_font, 'latex font'
        
        def string_to_type_internal(str)
          return Graphics::Styles::LaTeXFont.from_text(str)
        end
      end

      # Colormap
      class LaTeXFontBaseType < Type
        type_name :colormap, 'color map'
        
        def string_to_type_internal(str)
          return Graphics::Styles::ColorMap.from_text(str)
        end
      end

    end
  end
end
