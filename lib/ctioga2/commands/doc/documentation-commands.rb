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
    end
  end
end
