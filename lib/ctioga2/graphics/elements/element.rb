# element.rb: base class of all drawable elements
# copyright (c) 2006, 2007, 2008, 2009 by Vincent Fourmond: 
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details (in the COPYING file).


require 'ctioga2/utils'
require 'ctioga2/log'

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision: 948 $', '$Date: 2009-04-17 00:41:44 +0200 (Fri, 17 Apr 2009) $')

  # This module contains all graphical elements of CTioga2
  module Graphics

    # All elements that can be drawn onto a FigureMaker object
    module Elements
      
      # The base class for every single object that is drawn on
      # Tioga's output.
      class TiogaElement
        include Log

        # The parent Container.
        attr_accessor :parent

        # This function must be called with a FigureMaker object to
        # draw the contents of the TiogaElement onto it. It calls
        # #real_do, which should be redefined by the children. You can
        # redefine _do_ too if you need another debugging output.
        def do(f)
          debug "plotting #{self.inspect}"
          real_do(f)
        end

        # We plot everything but parent. If a prefix is given, it is prepended
        # to all lines but the first (for indentation)
        def inspect(prefix="")
          ret = "#<#{self.class.name}:\n"
          for i in instance_variables
            next if i == "@container"
            var = instance_variable_get(i)
            ret += "#{prefix}  - #{i} -> "
            if var.is_a? TiogaElement
              ret += "#{var.inspect("#{prefix}  ")}\n"
            else
              ret += "#{var.inspect}\n"
            end
          end
          ret += "#{prefix}>"
          return ret
        end

        protected
        
        def real_do(t)
          raise "Should be reimplemented by children"
        end
      end 
      

#       # A unique method call to a FigureMaker object.
#       class TiogaFuncall < TiogaElement

#         # _symbol_ is the symbol to be called, and the remainder will
#         # be used as arguments for the call.
#         def initialize(symbol, *args)
#           @symbol = symbol
#           @args = args
#         end

#         protected
        
#         def real_do(f)
#           f.send(@symbol, *@args)
#         end
#       end
    end
  end
end
