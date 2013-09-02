# ticks.rb: all aspects of axis ticks
# copyright (c) 2013 by Vincent Fourmond
  
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

require 'ctioga2/graphics/coordinates'

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Styles

      
      # This class describes where to place ticks on the target axis
      # and how to label them.
      class AxisTicks < BasicStyle

        include Log

        # The format of the tick labels.
        #
        # It is either a standard sprintf format or composed of one or
        # more of the following:
        # 
        # * %b followed by any usual format specifier: the tick value
        #   divided by the common power of 10
        # * %p the power of 10
        typed_attribute :format, "text"

        # The format of the last of the tick labels
        typed_attribute :format_last, "text"

        # The list of the position of major ticks
        #
        # @todo make it possible to provide a function to generate that ?
        typed_attribute :major, 'float-list'

        # The list of the position of minor ticks
        typed_attribute :minor, 'float-list'
        
        # The list of labels
        typed_attribute :labels, 'text-list'

        def self.tweak_format_string(str)
          return str.gsub("%b", "%2$").gsub("%p", "%3$d")
        end

        # Returns the specifications that should be added to the
        # information
        def ticks_specs(t, info, transform)
          ret = {}
          for k in %w{major_ticks minor_ticks labels}
            ret[k] = info[k]
          end
          if info['major']
            ret['minor_ticks'] = info['minor']
            ret['major_ticks'] = info['major']
          end
          fmt = @format

          if @major
            ret['minor_ticks'] = Dobjects::Dvector.new
            ret['major_ticks'] = Dobjects::Dvector.new(@major)

            fmt ||= "$%g$"
          end

          if @minor
            ret['minor_ticks'] = Dobjects::Dvector.new(@minor)
          end

          fmt_last = @format_last || fmt

          if @labels
            ret['labels'] = @labels
          elsif fmt
            ret['labels'] = []
            fmt = AxisTicks.tweak_format_string(fmt)
            fmt_last = AxisTicks.tweak_format_string(fmt_last)
            i = ret['major_ticks'].size
            common = Utils::common_pow10(ret['major_ticks'])
            fact = 10**(-common)
            for v in ret['major_ticks']
              i -= 1
              ret['labels'] << (i > 0 ? fmt : fmt_last) % [v, v*fact, common]
            end
          end
          return ret
        end
      end

    end
  end
end
