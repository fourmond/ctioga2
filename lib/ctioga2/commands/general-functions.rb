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
Evaluate its argument as Ruby code

# a := $(eval 2 + 2)
# # a is now 4

Keep in mind that variables in @ctioga2@ work by plain text replacement. 
They have no type. In particular, while this will work:

# a := 3
# b := $(eval $(a) * 3)
# # b is now 9

Doing the same kind of things with text will be somewhat not satisfying:

# a := "two words"
# b := $(eval $(a).split(/ /).first)

Running this will give the following syntax error:

@ [FATAL] (eval):1: syntax error, unexpected $end, expecting ')'
@ two words.split(/ /
@                    ^ while processing line 2 in file 'c.ct2'

Doing it right would require the use of a decent amount of quotes.
EOD

    FuncPoint = Function.new("point", "Get dataset point information") do |pm, what, spec, *rest|
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
      when "index", "idx"
        point.index
      else
        # The \ are not strictly speaking necessary, but they make
        # ruby-mode happier
        raise "\'#{what}\' unkown: which coordinate(s) of the point do you want ?"
      end

    end

    FuncPoint.describe <<EOD

Returns the requested information about the given point in a
dataset. Run this way:

# $(point x @234)

The first argument, here @x@ tells what we want to know about the
given point: its @x@ value (passing @x@), its @y@ value (passing @y@),
its @index@ (by passing @index@ or @idx@)
both its @x@ and @y@ ready to be used as coordinates for drawing
commands using @xy@. For instance, to draw a circle marker right in
the middle of the last dataset plotted, just run

# draw-marker $(point xy 0.5) Circle

The second argument specifies a dataset point, just like for 
{type: data-point}.

An optional third argument specifies the dataset from which one wants
the point information. Note that the dataset can also be specified
within the second argument, but it may be more readable to do it as an
optional third. It is parsed as {type: stored-dataset}


EOD


    
  end
end

