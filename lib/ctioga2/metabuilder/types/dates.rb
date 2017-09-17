# dates.rb: a Type to deal with dates
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

require 'time'
require 'ctioga2/utils'

module CTioga2

  module MetaBuilder

    # The module Types should be used for all subclasses of Type, to
    # keep the place clean and tidy.
    module Types

      # A combination date/time
      class DateTimeParameter < Type

        type_name :date_time, 'date', Time.new

        def string_to_type_internal(str)
          return begin
                   Time.parse(str)
                 rescue
                   nil
                 end
        end

      end
    end

  end
end
