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

  Version::register_svn_info('$Revision: 14 $', '$Date: 2009-04-27 21:49:16 +0200 (Mon, 27 Apr 2009) $')

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
    
  end
end

