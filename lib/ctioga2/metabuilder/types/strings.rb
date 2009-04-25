# strings.rb : Different Types to deal with strings
# Copyright (C) 2006 Vincent Fourmond
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

require 'ctioga2/utils'

module CTioga2

  Version::register_svn_info('$Revision: 950 $', '$Date: 2009-04-18 15:48:25 +0200 (Sat, 18 Apr 2009) $')


  module MetaBuilder

    # The module Types should be used for all subclasses of
    # Type, to keep the place clean and tidy.
    module Types

      # A String
      class StringParameter < Type

        type_name :string
        
        def type_name
          return 'text'
        end
        
        def string_to_type(str)
          return str
        end
      end

      # A piece of text representing the path to a file.
      class FileParameter < StringParameter

        type_name :file
        
        # The file filters, Qt style.
        attr_reader :filter

        def initialize(type)
          super(type)
          @filter = @type[:filter]
        end

        def type_name
          return 'file'
        end

      end

      # A String or a regular expression
      class StringOrRegexpParameter < Type

        type_name :string_or_regexp
        
        def type_name
          return 'regexp'
        end
        
        def string_to_type(str)
          if str =~ /^\/(.*)\/$/
            return Regexp.new($1)
          else
            return str
          end
        end

        def type_to_string(val)
          if val.is_a? String
            return val
          else
            return "/#{val}/"
          end
        end

      end

    end
  end
end
