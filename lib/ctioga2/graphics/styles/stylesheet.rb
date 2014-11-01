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

            if rest =~ /^\s*\*?\s*(>)?$/
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

          # p self.from_text("*")
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

        # A style bucket, a hash 'key' => 'value' associated with a
        # unique xpath
        class Bucket
          
          # The style information (a string->string hash).
          #
          # Not that it can actually be a string->typed stuff, since
          # most types accept that !
          attr_accessor :style

          # All the XPath associated with this style information
          attr_accessor :xpath

          # The xpath text initially used
          attr_accessor :xname

          def initialize(xp)
            @xname = xp
            @xpath = XPath.from_text(xp)
            @style = {}
          end

          def matches?(obj)
            if @xpath.matches?(obj)
              return true
            else
              return false
            end
          end

          # Returns the style, but with all the options normalized to
          # lowercase and without
          def normalized_style
            stl = {}
            for k,v in @style
              stl[k.gsub(/-/,"_").downcase] = v
            end
            return stl
          end

          # # Returns the style for the given object. DOES NOT CHECK
          # # that the object belongs to this Bucket.
          # def style_for(obj)
          #   @cache ||= {}
          #   if ! @cache.key?(obj.style_name)
          #     @cache[obj.style_name] = obj.style_class.from_hash(@style)
          #   end
          #   return @cache[obj.style_name]
          # end
        end

        # OK, so now we begin the StyleSheet class per se.
        #
        # The stylesheet class is but an ordered list of buckets.

        # The list of buckets
        attr_accessor :buckets

        # A hash "full xpath" -> bucket name, so that one can update a
        # bucket instead of just adding to it.
        attr_accessor :buckets_by_xpath

        def initialize()
          @buckets = []
          @buckets_by_xpath = {}
        end

        def set_style(xpath, style)
          for f in xpath.split(/\s*,\s*/) 
            bkt = get_bucket(f)
            bkt.style = style
          end
        end

        def update_style(xpath, style)
          for f in xpath.split(/\s*,\s*/) 
            bkt = get_bucket(f)
            bkt.style.merge!(style)
          end
        end

        def style_hash_for(obj)
          stl = {}
          for bkt in @buckets
            # p [bkt.xpath, bkt.matches?(obj), bkt.style]
            if bkt.matches?(obj)
              stl.merge!(bkt.normalized_style)
            end
          end

          # p [:s, stl]
          cls = obj.style_class
          rv = cls.convert_string_hash(stl)
          # p [:t, rv]
          return rv
        end

        def style_for(obj)
          return obj.style_class.from_hash(style_hash_for(obj))
        end

        def self.style_sheet
          @style_sheet ||= StyleSheet.new
          @style_sheet
        end

        def self.style_hash_for(obj)
          return self.style_sheet.style_hash_for(obj)
        end

        def self.style_for(obj)
          return self.style_sheet.style_for(obj)
        end

        def update_from_file(file)
        end

        def update_from_string(str)
          # First, strip all comments from the string
          str = str.gsub(/^\s*#.*/, '')

          str.gsub(/^\s*((?:[.#]?[\w-]+\s*>?\s*)+)\s*\{([^}]+)\}/m) do |x|
            xpath = $1
            smts = $2.split(/\s*;\s*/)
            
            stl = {}
            for s in smts
              if s =~ /\s*([\w-]+)\s*:\s*(.*)/m
                stl[$1] = $2
              else
                error { "Style not understood: #{s}" }
              end
            end
            update_style(xpath, stl)
          end

          p self
        end

        protected 

        def get_bucket(xpath)
          if ! @buckets_by_xpath.key? xpath
            @buckets << Bucket.new(xpath)
            @buckets_by_xpath[xpath] = @buckets.last
          end
          return @buckets_by_xpath[xpath]
        end

      end
    end
  end
end
