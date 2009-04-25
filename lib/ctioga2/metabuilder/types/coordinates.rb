# coordinates.rb : input of coordinates and dimensions in general
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

      # A class that produces a Graphics::Types::MarginsBox. It takes
      # one optional argument : a :default (:frame, :figure or :page),
      # see Graphics::Types::Dimensions::from_text for more information.
      class MarginsType < Type
        
        type_name :frame_margins, 'frame_margins'
        
        def string_to_type_internal(str)
          default = @type[:default] || :frame
          specs = str.split(/\s*,\s*/)
          if specs.size == 1
            specs = specs * 4
          elsif specs.size == 2
            specs = [specs[0], specs[0], specs[1], specs[1]]
          end
          if specs.size != 4
            raise IncorrectInput, "You need either 1, 2 or 4 elements to make up a margin specification"
          end
          return Graphics::Types::MarginsBox.new(*specs.map {|x|
                                                   Graphics::Types::Dimension::from_text(x, :x, default )})
        end
      end

      # A class that produces a Graphics::Types::Point. It takes one
      # optional argument: a :default (:frame, :figure or :page), see
      # Graphics::Types::Dimensions::from_text for more information.
      class PointType < Type
        
        type_name :point, 'point'
        
        def string_to_type_internal(str)
          default = @type[:default] || :figure
          return Graphics::Types::Point::from_text(str, default)
        end
      end


      # A class that produces a Graphics::Types::AlignedPoint. It
      # takes one optional argument : a :default (:frame, :figure or
      # :page), see Graphics::Types::Dimensions::from_text for more
      # information.
      class AlignedPointType < Type
        
        type_name :aligned_point, 'aligned_point'
        
        def string_to_type_internal(str)
          default = @type[:default] || :frame
          return Graphics::Types::AlignedPoint::from_text(str, default)
        end
      end

    end
  end
end
