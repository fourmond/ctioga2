# general-functions.rb: useful function definitions
# copyright (c) 2014 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'ctioga2/utils'
require 'ctioga2/data/point'

module CTioga2

  module Commands

    FuncEval = Function.new("eval", "Evaluate Ruby code") do |pm, code|
      eval(code)
    end

    FuncEval.describe <<EOD

EOD

    FuncPoint = Function.new("point", "Get dataset information") do |pm, what, spec, *rest|
      dataset = if rest.first
                  pm.data_stack.stored_dataset(rest.first)
                else
                  nil
                end
      
      point = Data::DataPoint::from_text(pm, spec, dataset)

      case what
      when "x", "X"
        point.x.to_s
      when "y", "Y"
        point.y.to_s
      when "xy", "XY"
        "%g,%g" % point.point
      else
        # The \ are not strictly speaking necessary, but they make
        # ruby-mode happier
        raise "\'#{what}\' unkown: which coordinate(s) of the point do you want ?"
      end

    end


    
  end
end

