# general-types.rb: various useful command types
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

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands
 
    # A file name.
    FileType = CmdType.new('file', :string, <<EOD)
A file name.
EOD

    # Plain text
    TextType = CmdType.new('text', :string, <<EOD)
Plain text.
EOD

    # A series of datasets
    DatasetType = CmdType.new('dataset', :string, <<EOD)
One expandable dataset.
EOD

    # Commands
    CommandsType = CmdType.new('commands', :string, <<EOD)
ctioga2 commands, such as the ones that could be found in
command files.
EOD

    BooleanType = CmdType.new('boolean', :boolean, <<EOD)
Yes or no.
EOD



    FloatType = CmdType.new('float', :float, <<EOD)
A floating-point number.
EOD

    IntegerType = CmdType.new('integer', :integer, <<EOD)
An integer.
EOD

    PartialFloatRangeType = CmdType.new('partial-float-range', 
                                        :partial_float_range, <<EOD)
A beginning:end range, where either of the endpoints can be ommitted.
EOD

    FloatRangeType = CmdType.new('float-range', 
                                 :float_range, <<EOD)
A beginning:end range.
EOD

    StringOrRegexp = CmdType.new('regexp', 
                                 :string_or_regexp, <<EOD)
A plain string or a regular expression (the latter being enclosed 
within /.../).
EOD


    # This one gets here since it messes up with syntax highlighting

    # A stored dataset.
    StoredDatasetType = CmdType.new('stored-dataset', 
                                    :string, <<EOD)
A dataset that has already been loaded. It is either:
* A number, in which case it specifies the index inside the stack. 0
is the first on that was pushed onto the stack (the oldest dataset),
1 the second, -1 the last one, -2 the one before the last and so
on. (it works just like Ruby's arrays).
* The name of a named dataset.
EOD


    
  end
end

