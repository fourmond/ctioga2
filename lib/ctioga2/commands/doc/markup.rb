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
      #
      # \todo we should provide tags to specifically mark TODO items
      # in documentation, in such a way that it would be easy to make
      # a list of them, and possibly ignore it for output.
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

          def dump_string
            return ""
          end

        end

        # A markup item representing plain text.
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

          def dump_string
            return "text: #{@text}"
          end

        end

        # A markup item representing verbatim text, with the given
        # class
        class MarkupVerbatim < MarkupItem
          # The text
          attr_accessor :text

          # The verbatim text class
          attr_accessor :cls
          
          def initialize(doc, text, cls)
            super(doc)
            @text = text
            @cls = cls
          end

          def to_s
            return text
          end

          def dump_string
            return "#{@cls}: #{@text}"
          end

        end

        # A link to a type/group/command
        class MarkupLink < MarkupItem
          # The object target of the link
          attr_accessor :target
          
          # _target_ is the name of the target, which can be of _type_
          # 'group', 'command', 'backend', 'type' and 'url'
          def initialize(doc, target, type)
            super(doc)
            if type =~ /url/
              @target = target
            else
              @target = doc.send("#{type}s")[target]
            end
          end

          def to_s
            if @target 
              begin
                return @target.name
              rescue NoMethodError
                return @target
              end
            else
              return "unknown"
            end
          end

          def dump_string
            return "link: #{@target}"
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
          
          def dump_string
            return @items.map {|x|
              "* #{x.map do |y| y.dump_string; end}\n"
            }.join('')
          end

        end

        # An item that contains a paragraph
        class MarkupParagraph < MarkupItem
          attr_accessor :elements
          
          def initialize(doc, elements)
            super(doc)
            @elements = elements
          end

          def to_s
            return @elements.map {|x| x.to_s }.join('')
          end

          def dump_string
            return "par: " + @elements.map {|x|
              "  #{x.dump_string}\n"
            }.join('')
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


        def dump
          puts "Number of elements: #{@elements.size}"
          for el in @elements
            puts "#{el.class} -> #{el.to_s}"
          end
        end


        # Parses the given _string_ and append the results to the
        # MarkedUpText's elements.
        #
        # Markup elements:
        #
        # * a line beginning with '> ' is an example for command-line
        # * a line beginning with '# ' is an example for use within a
        #   command file.
        # * a line beginning with '@ ' is a generic verbatim text.
        # * a line beginning with ' *' is an element of an
        #   itemize. The itemize finishes when a new paragraph is
        #   starting.
        # * a {group: ...} or {type: ...} or {command: ...} is a link
        #   to the element.
        # * a blank line marks a paragraph break.
        #
        # \todo Add elements to do some inline markup (such as bold,
        # code, italics; mostly code for now will do very fine)
        def parse_from_string(string)
          @last_type = nil
          @last_string = ""

          lines = string.split(/[ \t]*\n/)
          for l in lines
            l.chomp!
            case l
            when /^[#>@]\s(.*)/  # a verbatim line
              case l[0,1]
              when '#'
                type = :cmdfile
              when '>'
                type = :cmdline
              else
                type = :example
              end
              if @last_type == type
                @last_string << "#{$1}\n"
              else
                flush_element
                @last_type = type
                @last_string = "#{$1}\n"
              end
            when /^\s\*\s*(.*)/
              flush_element
              @last_type = :item
              @last_string = "#{$1}\n"
            when /^\s*$/          # Blank line:
              flush_element
              @last_type = nil
              @last_string = ""
            else
              case @last_type
              when :item, :paragraph # simply go on
                @last_string << "#{l}\n"
              else
                flush_element
                @last_type = :paragraph
                @last_string = "#{l}\n"
              end
            end
          end
          flush_element
        end

        protected 

        # Parses the markup found within a paragraph (ie: links and
        # other text attributes, but not verbatim, list or other
        # markings) and returns an array containing the MarkupItem
        # elements.
        def parse_paragraph_markup(doc, string)
          els = []
          while string =~ /\{(group|type|command|backend|url):\s*([^}]+?)\s*\}/
            els << MarkupText.new(doc, $`)
            els << MarkupLink.new(doc, $2, $1) 
            string = $'
          end
          els << MarkupText.new(doc, string)
          return els
        end

        # Adds the element accumulated so far to the @elements array.
        def flush_element
          case @last_type
          when :cmdline, :cmdfile
            @elements << MarkupVerbatim.new(@doc, @last_string, 
                                            "examples-#{@last_type}")
          when :example
            @elements << MarkupVerbatim.new(@doc, @last_string, "examples")
          when :paragraph
            @elements << 
              MarkupParagraph.new(@doc, 
                                  parse_paragraph_markup(doc, @last_string))
          when :item
            if @elements.last.is_a?(MarkupItemize)
              @elements.last.items << 
                parse_paragraph_markup(doc, @last_string)
            else
              @elements << 
                MarkupItemize.new(@doc, 
                                  [ parse_paragraph_markup(doc, @last_string)])
            end
          else                  # In principle, nil
            return
          end
        end


      end
      
      # A class dumping markup information to standard output
      class Markup
        # The Doc object the Markup class should dump
        attr_accessor :doc

        def initialize(doc)
          @doc = doc
        end
        
        # Dumps the markup of all commands
        def write_commands(out = STDOUT)
          cmds, groups = @doc.documented_commands

          for g in groups
            out.puts "Group markup: #{g.name}"
            out.puts dump_markup(g.description)

            commands = cmds[g].sort {|a,b|
              a.name <=> b.name
            }
            
            for cmd in commands
              out.puts "Command: #{cmd.name}"
              out.puts dump_markup(cmd.long_description)
            end
          end
        end

        # Dumps the markup of all types
        def write_types(out = STDOUT)
          types = @doc.types.sort.map { |d| d[1]}
          for t in types
            out.puts "Type: #{t.name}"
            out.puts dump_markup(t.description)
          end
        end

        def dump_markup(items)
          if items.is_a? String 
            mup = MarkedUpText.new(@doc, items)
            return dump_markup(mup.elements)
          end
          return items.map { |x| "-> #{x.dump_string}\n"}
        end

      end
    end

  end
end
