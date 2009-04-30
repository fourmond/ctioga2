# markup.rb: simple markup system used wirhin the documentation.
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

  module Commands

    module Documentation

      # The documentation strings are written in a simple markup
      # language. 
      class MarkedUpText

        # Do we really need logging ?
        include Log

        # The base class for markup items.
        class MarkupItem
          # The documentation object
          attr_accessor :doc

          def initialize(doc)
            @doc = doc
          end

          def to_s
          end
        end

        # A markup item representing plain text.
        #
        # TODO: in to_s a simple word-wrapping algorithm could be
        # used.
        class MarkupText < MarkupItem
          # The text
          attr_accessor :text
          
          def initialize(doc, text = "", strip = true)
            super(doc)
            @text = text
            if strip
              @text.gsub!(/\n/, " ")
            end
          end

          def to_s
            return text
          end
        end

        # A link to a type/group/command
        class MarkupLink < MarkupItem
          # The object target of the link
          attr_accessor :target
          
          # _target_ is the name of the target, which can be of _type_
          # 'group', 'command' and 'type'.
          def initialize(doc, target, type)
            super(doc)
            @target = doc.send("#{type}s")[target]
          end

          def to_s
            if @target
              return @target.name
            else
              return "unknown"
            end
          end
        end

        # An itemize object 
        class MarkupItemize < MarkupItem

          # An array of arrays of MarkupItem, each representing an
          # element of the itemize object.
          attr_accessor :items
          
          def initialize(doc, items = [])
            super(doc)
            @items = items
          end
          
          def to_s
            str = ""
            for i in @items
              str << " * "
              for j in i
                str << j.to_s 
              end
              str << "\n"
            end
            return str
          end
        end

        # A simple item that begins a new paragraph.
        class MarkupParagraph
          def to_s
            return "\n\n"
          end
        end

        # The reference Doc object
        attr_accessor :doc

        # The elements that make up the MarkedUpText
        attr_accessor :elements

        # Creates a MarkedUpText object.
        def initialize(doc, text = nil)
          @elements = []
          @doc = doc
          if text
            parse_from_string(text)
          end
        end

        def parse_from_string(string)
          self.class.parse_string_to_array(@elements, @doc, string)
        end

        def dump
          puts "Number of elements: #{@elements.size}"
          for el in @elements
            puts "#{el.class} -> #{el.to_s}"
          end
        end

        # Parses the given _string_ and append the resulting
        # MarkupItem elements to the _target_ array.
        #
        # Markup elements:
        # 
        # * a line beginning with ' *' is an element of an
        #   itemize. The itemize finishes when a new paragraph is
        #   starting.
        # * a {group: ...} or {type: ...} or {command: ...} is a link
        #   to the element.
        # * a blank line marks a paragraph break.
        def self.parse_string_to_array(target, doc, string)
          # First, we split the string into paragraphs:
          # 
          # TODO: if I ever want to include a "verbatim" environment,
          # which could be good for examples, the best way to place it
          # would probably be here, although after itemize parsing
          # might still be a good option.
          paragraphs = string.split(/^\s*\n/)
          first = true
          for par in paragraphs
            # Then, we split into itemize elements:
            if !first 
              target << MarkupParagraph.new
            else
              first = false
            end
            
            subelements = par.split(/^\s\*\s*/)
            els = []
            for el in subelements
              # Now, we have paragraphs, in which we only need to go
              # looking for markup elements.
              sub_els = []
              # TODO: here, to insert new kinds of markup (italics,
              # bold), the only thing to do is to extend the regular
              # expression using |.
              while el =~ /\{(group|type|command):\s*([^}]+?)\s*\}/
                sub_els << MarkupText.new(doc, $`)
                sub_els << MarkupLink.new(doc, $2, $1) 
                el = $'
              end
              sub_els << MarkupText.new(doc, el)
              els << sub_els
            end
            target.concat(els[0])
            if els.size > 1
              target << MarkupItemize.new(doc, els[1..-1])
            end
          end
        end


      end
    end

  end
end
