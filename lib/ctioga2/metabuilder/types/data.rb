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

  module MetaBuilder
    module Types

      class DataPointType < Type
        
        type_name :data_point, 'data-point'
        
        def string_to_type_internal(str)
          return Data::DataPoint.from_text(PlotMaker.plotmaker,str)
        end
      end

      class LevelType < Type
        
        type_name :level, 'level'
        
        # @todo This should be modified eventually to mirror the
        # DataPoint, but for now, no.
        def string_to_type_internal(str)
          return [str.to_f, PlotMaker.plotmaker.data_stack.last]
        end
      end

    end
  end
end
