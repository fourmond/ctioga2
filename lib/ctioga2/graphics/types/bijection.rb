# bijection.rb: a bijection representing a reversible coordinate transformation
# copyright (c) 2009 by Vincent Fourmond
  
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

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Types

      # This class represents a *reversible* arbitrary coordinate
      # transformation, such as the ones that could be desirable for
      # alternative axes. Characterized by two Block objects, #from
      # and #to, that converts respectively from and to the target
      # coordinates.
      class Bijection

        # A Block converting from the target coordinates
        attr_accessor :from

        # A Block converting to the target coordinates
        attr_accessor :to

        # Creates a new Bijection with the given blocks.
        def initialize(from, to = nil)
          @from = from
          @to = to || @from
        end

        # Converts a vector to the target coordinates
        def convert_to(vect)
          return vect.map do |x|
            self.to.call(x)
          end
        end

        # Converts a vector from the target coordinates
        def convert_from(vect)
          return vect.map do |x|
            self.from.call(x)
          end
        end

        # Creates a Bijection from a text representation.
        #
        # Takes functions of _x_. Takes two blocks _from_ _to_
        # separated by :: -- or only one block in the case of an
        # involution (very common, actually, all 1/x transforms).
        #
        # TODO: few things around here to change... in particular,
        # I should try to find a way to include Math... 
        #
        # TODO: add very common cases ?
        def self.from_text(spec)
          blocks = spec.split(/::/).map do |code|
            eval("proc do |x|\n#{code}\nend")
          end
          return Bijection.new(*blocks)
        end
      end

    end
  end
end

