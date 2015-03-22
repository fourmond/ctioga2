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

  module Commands

    module Documentation

      # Generation of XHTML snippets (not full pages) that document
      # the commands/groups and types known to CTioga2.
      class HTML
        
        # The Doc object the HTML class should document
        attr_accessor :doc

        # The base URL for the file where the types are documented.
        attr_accessor :types_url

        # The base URL for the file where the backends are documented.
        #
        # \todo maybe this should be turned into a directory, and each
        # file would document a backend on its own ? That would make
        # sense, but that would be rather difficult, I have to admit.
        attr_accessor :backends_url

        # The base URL for file where commands and groups are
        # documented.
        attr_accessor :commands_url

        def initialize(doc)
          @doc = doc
          @types_url = "types.html"
          @commands_url = "commands.html"
          @backends_url = "backends.html"
          @functions_url = "functions.html"
        end

        def write_page_menu(opts, out)
          if !opts['page-menu'] or opts['page-menu'] =~ /menu|full/i
            yield out
          end
        end

        def write_page(opts, out)
          if !opts['page-menu'] or opts['page-menu'] =~ /page|full/i
            yield out
          end
        end

        def write_functions(opts, out = STDOUT)
          funcs = @doc.functions
          names = funcs.keys.sort
          
          write_page_menu(opts, out) do |out|
            out.puts "<div class='quick-jump'>"
            out.puts "<h3>Quick jump</h3>"
            out.puts "<ul>\n"
            for n in names
              out.puts "<li><a href='#func-#{n}'>#{n}</a></li>\n"
            end
            out.puts "</ul>\n"
            out.puts "</div>"
          end
          write_page(opts, out) do |out|
            for n in names
              f = funcs[n]
              out.puts 
              out.puts "<h3 class='function' id='func-#{n}'>#{n} - #{f.short_description}</h3>"
              out.puts markup_to_html(f.description)
            end
          end
        end

        # Ouputs HTML code to document all groups and commands 
        def write_commands(opts, out = STDOUT)
          cmds, groups = @doc.documented_commands

          if opts['snippets']
            require 'yaml'
            snippets = begin
                         YAML.load(IO.readlines(opts['snippets']).join())
                       rescue Exception => e
                         Log::error { "Failed to load snippets file '#{opts['snippets']}'\n => #{e.inspect}" }
                         {}
                       end
          end

          write_page_menu(opts, out) do |out|
            out.puts "<div class='quick-jump'>"
            out.puts "<h3>Quick jump</h3>"
            out.puts "<ul>\n"
            for g in groups
              out.puts "<li><a href='#group-#{g.id}'>#{g.name}</a></li>\n"
            end
            out.puts "</ul>\n"
            out.puts "</div>"
          end
          
          write_page(opts, out) do |out|
            for g in groups
              out.puts 
              out.puts "<h3 class='group' id='group-#{g.id}'>#{g.name}</h3>"
              out.puts markup_to_html(g.description)
              
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
                if snippets
                  snpts = snippets[cmd.name]
                  if snpts
                    str = ""
                    for k in snpts.keys.sort
                      s = snpts[k]
                      ln = s[:line].chomp
                      # if ln[-1] == '\\'
                      #   ln = ln[0..-2]
                      # end
                      # Strip links from the line
                      ln.gsub!(/<a[^>]+>(.*?)<\/a>/) { || $1 }
                      str += "<pre class='#{s[:cls]}'><a href='#{k}'>#{ln}</a></pre>\n"
                    end
                    out.puts "<div class='snippets'><h5>Examples:</h5>#{str}</div>"
                  end
                end
              end
            end
          end
        end

        # Write a HTML table documenting all command-line options.
        def write_command_line_options(opts, out = STDOUT)
          cmds, groups = @doc.documented_commands

          out.puts "<table>"
          for g in groups
            out.puts "<tr><th colspan='3'>#{g.name}</th></tr>"
            commands = cmds[g].sort {|a,b|
              a.long_option <=> b.long_option
            }
            for cmd in commands
              opts = cmd.option_strings
              link = "<a href='#{@commands_url}#command-#{cmd.name}'>"
              out.puts "<tr><td><code>#{link}#{opts[0]}</a></code></td>"
              out.puts "<td><code>#{link}#{opts[1]}</a></code></td>"
              out.puts "<td>#{opts[2]}</td></tr>"
            end
          end
          out.puts "</table>"

        end


        # Ouputs HTML code to document all types
        def write_types(opts, out = STDOUT)
          types = @doc.types.sort.map { |d| d[1]}


          write_page_menu(opts, out) do |out|
            out.puts "<div class='quick-jump'>"
            out.puts "<h3>Quick jump</h3>"
            out.puts "<ul>\n"
            for t in types
              out.puts "<li><a href='#type-#{t.name}'>#{t.name}</a></li>\n"
            end
            out.puts "</ul>\n"
            out.puts "</div>"
          end
 
          write_page(opts, out) do |out|
            for t in types
              out.puts
              out.puts "<h4 id='type-#{t.name}' class='type'>#{t.name}</h4>\n"
              out.puts markup_to_html(t.description)
              out.puts            # There is no need to wrap the markup
              # in a paragraph.
            end
          end
        end
        

        # Ouputs HTML code to all backends
        def write_backends(opts, out = STDOUT)
          backends = @doc.backends.sort.map { |d| d[1]}


          write_page_menu(opts, out) do |out|
            out.puts "<div class='quick-jump'>"
            out.puts "<h3>Quick jump</h3>"
            out.puts "<ul>\n"
            for b in backends
              out.puts "<li><a href='#backend-#{b.name}'>#{b.name}</a></li>\n"
            end
            out.puts "</ul>\n"
            out.puts "</div>"
          end
          
          write_page(opts, out) do |out|
            for b in backends
              out.puts
              out.puts "<h3 id='backend-#{b.name}' class='backend'><code>#{b.name}</code>: #{b.long_name}</h3>\n"
              out.puts markup_to_html(b.description)
              out.puts
              for param in b.param_list
                out.puts "<h4 id='backend-#{b.name}-#{param.name}'>Parameter: #{param.name}</h4>"
                out.puts "<p><code>/#{param.name}=<a href='#{@types_url}#type-#{param.type.name}'>#{param.type.name}</a></code></p>"
                out.puts markup_to_html(param.description)
              end
            end
          end
        end

        # Write a summary list of all style items
        def write_styles(opts, out = STDOUT)

          styles = Graphics::Elements::TiogaElement::styled_classes

          names = styles.keys.sort
          
          write_page_menu(opts, out) do |out|
            out.puts "<div class='quick-jump'>"
            out.puts "<h3>Quick jump</h3>"
            out.puts "<ul>\n"
            for k in names
              out.puts "<li><a href='#style-#{k}'>#{k}</a></li>\n"
            end
            out.puts "</ul>\n"
            out.puts "</div>"
          end

          write_page(opts, out) do |out|
            for n in names
              out.puts "<h3 id='style-#{n}' class='style'><code>#{n}</code></h3>\n"
              cls = styles[n].style_class
              if cls
                aliases = cls.defined_aliases
                out.puts "<ul>\n"
                
                opts = cls.options_hash
                op_names = opts.keys.sort
                for k in op_names
                  type = opts[k].type
                  extra = if aliases.key? k
                            " (alias for <code>#{cls.normalize_out(aliases[k])}</code>)"
                          else
                            ""
                          end
                            
                  puts "<li><code>#{cls.normalize_out(k)}</code>#{extra}: <a href='#{@types_url}#type-#{type.name}'>#{type.name}</a></li>\n"
                end
                out.puts "</ul>\n"

              else
                out.puts "No specific style information"
              end
            end
          end

        end
        

        protected

        # The string that represents a full command
        def command_documentation(cmd)
          str = "<h4 class='command' id='command-#{cmd.name}'>Command: <code>#{cmd.name}</code></h4>\n"
          str << "<p class='synopsis'>\n<span class='bold'>Synopsis (file)</span>\n"

          str << "</p>\n<pre class='examples-cmdfile'>"
          str << "<span class='cmd'>#{cmd.name} "
          str << cmd.arguments.map { |arg|
            "<a class='argument' href='#{@types_url}#type-#{arg.type.name}'>#{arg.displayed_name}</a>"
          }.join(' ')
          if cmd.has_options?
            if(cmd.arguments.size > 0)
              str << " "
            end
            str << "/option=..."
          end
          str << "</span>\n"
          str << "</pre>\n"

          # Command-line file synopsis
          str << "<p class='synopsis'>\n<span class='bold'>Synopsis  (command-line)</span>\n"
          args = cmd.arguments.map { |arg|
            "<a class='argument' href='#{@types_url}#type-#{arg.type.name}'>#{arg.displayed_name}</a>"
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
              "<a href='#{@types_url}#type-#{arg.type.name}'><code>#{cmd.normalize_option_name(k)}</code></a>\n"
            end
            str << opts.join(' ')
            str << "</p>"
          end
          # Now, the description:
          str << markup_to_html(cmd.long_description)
          return str
        end

        # Takes up an array of MarkupItem objects and returns its
        # equivalent in HTML format. Alternativelely, it can take a
        # String and feed it to MarkedUpText.
        #
        # \todo escape correctly the produced HTML code...
        def markup_to_html(items)
          if items.is_a? String 
            mup = MarkedUpText.new(@doc, items)
            return markup_to_html(mup.elements)
          end
          str = ""
          for it in items
            case it
            when MarkedUpText::MarkupText
              el = nil
              case it.kind
              when :code
                el = "code"
              end
              if el
                prefix = "<#{el}>"
                suffix = "</#{el}>"
              else
                prefix = ""
                suffix = ""
              end
              str << "#{prefix}#{it.to_s}#{suffix}"
            when MarkedUpText::MarkupLink
              case it.target
              when Command
                link = "#{@commands_url}#command-#{it.target.name}"
              when Function
                link = "#{@functions_url}#func-#{it.target.name}"
              when CommandGroup
                link = "#{@commands_url}#group-#{it.target.id}"
              when CommandType
                link = "#{@types_url}#type-#{it.target.name}"
              when Data::Backends::BackendDescription
                link = "#{@backends_url}#backend-#{it.target.name}"
              when String       # plain URL target
                link = "#{it.target}"
              else
                raise "The link target should be either a group, a command or a type, but is a #{it.target.class} (#{it.dbg.inspect})"
              end
              str << "<a href='#{link}'>#{it.to_s}</a>"
            when MarkedUpText::MarkupItemize
              str << "<ul>\n"
              for x in it.items
                str << "<li>#{markup_to_html(x)}</li>\n"
              end
              str << "</ul>\n"
            when MarkedUpText::MarkupParagraph
              str << "<p>\n#{markup_to_html(it.elements)}\n</p>\n"
            when MarkedUpText::MarkupVerbatim
              str << "<pre class='#{it.cls}'>#{it.text}</pre>\n"
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
