# stylesheet.rb: handling of style sheets
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
require 'ctioga2/log'

require 'ctioga2/graphics/coordinates'

# This module contains all the classes used by ctioga
module CTioga2

  module Graphics

    module Styles

      # A StyleSheet is a simple implementation of CSS-like facilities
      # in ctioga2. As in CSS, it recognizes id and classes, and type.
      class StyleSheet

        # An element in a XPath
        class XPathElement
          
          # The type -- or nil if not selecting on type
          attr_accessor :obj_type

          # The class -- or nil if not selecting on class
          attr_accessor :obj_class

          # The ID, or nil if not selecting on id
          attr_accessor :obj_id

          # If this flag is on, the object has to be the direct parent
          # of the child below.
          attr_accessor :direct_parent

          # A XPathElement is a series of elements (\w and - allowed),
          # optionnally followed by a > sign. No space allowed,
          # excepted before the > sign
          def parse_string(txt)


            rest = txt.gsub(/([.#]?)([\w-]+)/) do |x|
              if $1 == "."
                @obj_class = $2
              elsif $1 == "#"
                @obj_id = $2
              else
                @obj_type = $2
              end
              ""
            end

            if rest =~ /^\s*(>)?$/
              if $1 == ">"
                @direct_parent = true
              end
            else
              raise "Incorrect XPath element: #{txt}"
            end

          end
          
          def self.from_text(txt)
            a = XPathElement.new
            a.parse_string(txt)
            return a
          end

          def matches?(obj)
            if @obj_type && (obj.style_name != @obj_type)
              return false
            end
            if @obj_class && !obj.object_classes.include?(@obj_class)
              return false
            end
            if @obj_id && (obj.object_id != @obj_id)
              return false
            end
            return true
          end

          # p self.from_text("bidule")
          # p self.from_text(".bidule")
          # p self.from_text("#bidule")
          # p self.from_text("b#a.cls")
          # p self.from_text("b#a.cls >")

          # p self.from_text("$sdf")
          
        end

        # An XPath, ie a series of XPathElement from outermost to
        # innermost.
        class XPath

          # From the innermost to outermost
          attr_accessor :elements

          def parse_string(txt)
            @elements = txt.gsub(/\s*>/, '>').split(/\s+/).reverse.map do |x|
              XPathElement.from_text(x)
            end
          end

          def self.from_text(txt)
            a = XPath.new
            a.parse_string(txt)
            return a
          end

          # Returns true if the innermost element has a type
          def typed?
            if @elements.first.obj_type
              return true
            else
              return false
            end
          end

          def matches?(obj)
            return match_chain(obj, @elements)
          end

          protected
          
          def match_chain(obj, elems)
            if ! elems.first.matches?(obj)
              return false
            end
            
            if elems.size <= 1
              return true
            end

            np = obj.object_parent
            if ! np
              return false
            end
            if elems[1].direct_parent
              return match_chain(np, elems[1..-1])
            else
              while np
                if match_chain(np, elems[1..-1])
                  return true
                else
                  np = np.object_parent
                end
              end
            end
            return false
          end
        end

        

      end
    end
  end
end
