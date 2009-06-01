# doc.rb: a class holding all informations
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
require 'ctioga2/commands/commands'
require 'ctioga2/commands/doc/help'
require 'ctioga2/commands/doc/man'
require 'ctioga2/commands/doc/html'
require 'ctioga2/commands/doc/markup'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    # The base of the 'self-documentation' of CTioga2
    module Documentation


      # Documentation generation
      DocumentationGenerationGroup = 
        CmdGroup.new('doc', "Documentation generation",
                     "Automatic documentation generation.", 
                     1000, true)
      
      
      # Display help on the command-line
      WriteManualPage = 
        Cmd.new("write-manual-page", nil, "--write-man", 
                [ 
                 CmdArg.new('text', 'version'),
                 CmdArg.new('file'),
                ]) do |plotmaker, version, file|
        m = Man.new(plotmaker.interpreter.doc)
        m.write_manual_page(version, file)
      end
      
      WriteManualPage.describe("Writes a manual page based on a template",
                               <<EOH, DocumentationGenerationGroup)
Writes a manual page based on a template
EOH


      WriteHTMLCommands = 
        Cmd.new("write-html-commands", nil, "--write-html-commands", 
                []) do |plotmaker|
        html = HTML.new(plotmaker.interpreter.doc)
        html.write_commands()
      end
      
      WriteHTMLCommands.describe("HTML documentation for group and commands",
                                 <<EOH, DocumentationGenerationGroup)
Prints the HTML documentation for group and commands to standard output.
EOH

      WriteHTMLTypes = 
        Cmd.new("write-html-types", nil, "--write-html-types", 
                []) do |plotmaker|
        html = HTML.new(plotmaker.interpreter.doc)
        html.write_types()
      end
      
      WriteHTMLTypes.describe("HTML documentation for types",
                              <<EOH, DocumentationGenerationGroup)
Prints the HTML documentation for all types.
EOH

      DumpCommandMarkup = 
        Cmd.new("dump-command-markup", nil, "--dump-command-markup", 
                []) do |plotmaker|
        markup = Markup.new(plotmaker.interpreter.doc)
        markup.write_commands()
      end
      
      DumpCommandMarkup.describe("Dump markup for commands and groups",
                                 <<EOH, DocumentationGenerationGroup)
Dumps the parsed markup for commands and groups. Used for debugging
purposes.
EOH

      DumpTypesMarkup = 
        Cmd.new("dump-types-markup", nil, "--dump-types-markup", 
                []) do |plotmaker|
        markup = Markup.new(plotmaker.interpreter.doc)
        markup.write_types()
      end
      
      DumpTypesMarkup.describe("Dump markup for types and groups",
                               <<EOH, DocumentationGenerationGroup)
Dumps the parsed markup for types and groups. Used for debugging
purposes.
EOH

    end
  end
end
