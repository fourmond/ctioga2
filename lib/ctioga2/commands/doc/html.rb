# html.rb: html output for internal documentation
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details (in the COPYING file).

require 'ctioga2/utils'
require 'ctioga2/commands/commands'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    module Documentation

      # Generation of XHTML snippets (not full pages) that document
      # the commands/groups and types known to CTioga2.
      class HTML
        
        # The Doc object the HTML class should document
        attr_accessor :doc

        # The base URL for file where types are documented.
        attr_accessor :types_url

        # The base URL for file where commands and groups are
        # documented.
        attr_accessor :commands_url

        def initialize(doc)
          @doc = doc
          @types_url = "types.html"
          @commands_url = "commands.html"
        end

        # Ouputs HTML code to document all groups and commands 
        def write_commands(out = STDOUT)
          cmds, groups = @doc.documented_commands

          out.puts "Quick jump to a specific group of commands:\n"
          out.puts "<ul>\n"
          for g in groups
            out.puts "<li><a href='#group-#{g.id}'>#{g.name}</a></li>\n"
          end
          out.puts "</ul>\n"
          
          for g in groups
            out.puts 
            out.puts "<h3 class='group' id='group-#{g.id}'>#{g.name}</h3>"
            out.puts "<p>"
            out.puts markup_to_html(g.description)
            out.puts "</p>"

            commands = cmds[g].sort {|a,b|
              a.name <=> b.name
            }
            
            out.puts "<p>"
            out.puts "<span class='bold'>Available commands:</span>\n"
            out.puts commands.map {|c|
              "<a href='#command-#{c.name}'><code>#{c.name}</code></a>"
            }.join(' ')
            out.puts "</p>"

            for cmd in commands
              out.puts
              out.puts command_documentation(cmd)
            end
          end

        end

        # Ouputs HTML code to document all types
        def write_types(out = STDOUT)
          types = @doc.types.sort.map { |d| d[1]}


          out.puts "Quick jump to a specific type:\n"
          out.puts "<ul>\n"
          for t in types
            out.puts "<li><a href='#type-#{t.name}'>#{t.name}</a></li>\n"
          end
          out.puts "</ul>\n"
 
          for t in types
            out.puts
            out.puts "<h4 id='type-#{t.name}' class='type'>#{t.name}</h4>\n"
            out.puts "<p>\n"
            out.puts markup_to_html(t.description)
            out.puts "</p>\n"
          end
        end
        

        protected

        # The string that represents a full command
        def command_documentation(cmd)
          str = "<h4 class='command' id='command-#{cmd.name}'>Command: <code>#{cmd.name}</code></h4>\n"
          str << "<p class='synopsis'>\n<span class='bold'>Synopsis (file)</span>\n"

          str << "</p>\n<pre class='examples-cmdfile'>"
          str << "<span class='cmd'>#{cmd.name}("
          str << cmd.arguments.map { |arg|
            "<a class='argument' href='#{@types_url}#type-#{arg.type.name}'>#{arg.displayed_name}</a>"
          }.join(',')
          if cmd.has_options?
            str << ",option=..."
          end
          str << ")</span>\n"
          str << "</pre>\n"

          # Command-line file synopsis
          str << "<p class='synopsis'>\n<span class='bold'>Synopsis  (command-line)</span>\n"
          args = cmd.arguments.map { |arg|
            "<a class='argument' href='#{@types_url}#type-#{arg.type.name}'>#{arg.displayed_name.upcase}</a>"
          }.join(' ')
          if cmd.has_options?
            args << " /option=..."
          end
          str << "</p>\n<pre class='examples-cmdline'>"
          if cmd.short_option
            str << "<span class='cmdline'>-#{cmd.short_option} "
            str << args
            str << "</span>\n"
          end
          str << "<span class='cmdline'>--#{cmd.long_option} "
          str << args
          str << "</span>\n"
          str << "</pre>"
          
          if cmd.has_options?
            str << "<p class='synopsis'><span class='bold'>Available options</span>:\n"
            opts = cmd.optional_arguments.sort.map do |k,arg|
              "<a href='#{@types_url}#type-#{arg.type.name}'><code>#{k}</code></a>\n"
            end
            str << opts.join(' ')
            str << "</p>"
          end
          str << "<p>"
          # Now, the description:
          str << "#{markup_to_html(cmd.long_description)}\n"
          str << "</p>\n"
          return str
        end

        # Takes up an array of MarkupItem objects and returns its
        # equivalent in HTML format. Alternativelely, it can take a
        # String and feed it to MarkedUpText.
        #
        # TODO: escape correctly the produced HTML code...
        def markup_to_html(items)
          if items.is_a? String 
            mup = MarkedUpText.new(@doc, items)
            return markup_to_html(mup.elements)
          end
          str = ""
          for it in items
            case it
            when MarkedUpText::MarkupText
              str << it.to_s
            when MarkedUpText::MarkupLink
              case it.target
              when Command
                link = "#{@commands_url}#command-#{it.target.name}"
              when CommandGroup
                link = "#{@commands_url}#group-#{it.target.id}"
              when CommandType
                link = "#{@types_url}#type-#{it.target.name}"
              else
                raise "The link target should be either a group, a command or a type, but is a #{it.target.class}"
              end
              str << "<a href='#{link}'>#{it.to_s}</a>"
            when MarkedUpText::MarkupItemize
              str << "</p>\n<ul>\n"
              for x in it.items
                str << "<li>#{markup_to_html(x)}</li>\n"
              end
              str << "</ul>\n<p>\n"
            when MarkedUpText::MarkupParagraph
              str << "</p>\n<p>"
            else
              raise "Markup #{it.class} isn't implemented yet for HTML"
            end
          end
          return str
        end

        
      end

    end
  end
end
