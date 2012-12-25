# utils.rb: Some small utility functions
# Copyright (c) 2006-2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

module CTioga2

  # An exception to raise upon to-be-implemented-one-day features
  class YetUnimplemented < Exception
  end

  
  # A small module to deal with versions and dates
  module Version

    # The current version of the program.
    def self.version
      if CTIOGA_VERSION =~ /SVN/
        return "SVN, revision #{SVN_INFO['revision']}#{SVN_INFO['suffix']}, #{SVN_INFO['date']}"
      else
        return CTIOGA_VERSION
      end
    end

    # All files should use this function with the appropriate
    # arguments and have the Date and Revision svn:keyword:. Use this
    # way:
    #
    #  Version::register_svn_info('$Revision$', '$Date$')
    #
    # To set the correct properties, the following command-line can be
    # used:
    #
    #  svn propset svn:keywords 'Date Revision'
    def self.register_svn_info(rev_str, date_str)
      if rev_str =~ /(\d+)/
        rev = $1
        str = 'Date'
        date = date_str.gsub(/\$#{str}:\s*(.*)\$/) { $1 }
        if SVN_INFO['revision'] < rev.to_i
          SVN_INFO['revision'] = rev.to_i
          SVN_INFO['date'] = date
        end
        # Hmmm, we want to see how many revisions is git ahead of SVN
        if rev_str =~ /(\+git\d+)/
          SVN_INFO['suffix'] = $1
        end
      end
    end

    # Returns the date ctioga2 was last modified.
    def self.last_modified_date
      SVN_INFO['date'] =~ /([\d-]+)/
      return $1
    end


    # The constants are moved here, as they disturb rdoc parsing.


    # Informations collected about subversion revisions
    SVN_INFO = { 
      'revision' => 0,
      'date' => "old",
      'suffix' => ''
    }

    # The position of the URL, used for getting the version
    SVN_URL = '$HeadURL$'
    
    # The version of ctioga2
    CTIOGA_VERSION = if SVN_URL =~ /releases\/ctioga2-([^\/]+)/
                       $1
                     else
                       "SVN version"
                     end

    register_svn_info('$Revision$', '$Date$')

  end

  # Various utilities
  module Utils
    # Takes a string a returns a quoted version that should be able to
    # go through shell expansion.
    def self.shell_quote_string(str)
      if str =~ /[\s"*$()\[\]{}';\\]/
        if str =~ /'/
          a = str.gsub(/(["$\\])/) { "\\#$1" }
          return "\"#{a}\""
        else 
          return "'#{str}'"
        end
      else
        return str
      end
    end

    # Takes two arrays of the same size (vectors) and mix them
    # a * r + b * (1 - r)
    def self.mix_objects(a,b,r)
      ret = a.dup
      a.each_index do |i|
        ret[i] = a[i] * r + b[i] * (1 - r)
      end
      return ret
    end

    # Quotes a string so it can be included directly within a
    # \pdfinfo statement (for instance).
    def self.pdftex_quote_string(str)
      return str.gsub(/([%#])|([()])|([{}~_^])|\\/) do 
        if $1
          "\\#{$1}"
        elsif $2                  # Quoting (), as they can be quite nasty !!
          "\\string\\#{$2}"
        elsif $3
          "\\string#{$3}"
        else                      # Quoting \
          "\\string\\\\"
        end
      end
    end

    # Binomial coefficients (for the smooth filter)
    def self.cnk(n,k)
      res = 1.0
      n.downto(n - k) { |i| res *= i}
      k.downto(1) {|i| res = res/i }
      return res
    end

    # This converts a text formula that can contain:
    # * any litteral thing
    # * references to columns in the form of \$1 for column 1 (ie the
    #   second one)
    # * references to named columns in the form $name$
    # * references to parameters
    #
    # The return value is ready to be passed to Dvector.compute_formula
    def self.parse_formula(formula, parameters = nil, header = nil)
      formula = formula.dup
      if parameters
        for k,v in parameters
          formula.gsub!(/\b#{k}\b/, v.to_s)
        end
      end
      formula.gsub!(/\$(\d+)/, 'column[\1]')
      if header
        for k,v in header
          formula.gsub!("$#{k}$", "column[#{v}]")
        end
      end
      return formula
    end
    

  end

  # This class implements a Hash whose values can also be retrieved by
  # pattern matching.
  class RegexpHash

    # Hash for non regexp keys
    attr_accessor :hash

    # Hash for regexp keys
    attr_accessor :regexp_hash

    def initialize()
      @hash = {}
      @regexp_hash = {}
    end

    # Sets the key to the given value
    def []=(key, value)
      if Regexp === key
        @regexp_hash[key] = value
      else
        @hash[key] = value
      end
    end

    # Gets the value corresponding to the key, using pattern matching
    # should the need arise.
    def [](key)
      if @hash.key?(key)
        return @hash[key]
      else
        for k,v in @regexp_hash
          if k === key
            return v
          end
        end
      end
      return nil
    end

    def keys_for(value)
      ret = []
      for k,v in @hash
        if value == v
          ret << k
        end
      end
      return ret
    end

  end

end

# Here, we define an additional function in the Hash class: without
class Hash
  def without(*args)
    ret = self.dup
    for a in args.flatten
      ret.delete(a)
    end
    return ret
  end
end

begin
  # This is a dirty hack in order to ensure that the SVN revision
  # information is kept up-to-date even when using git-svn. This
  # file is not present in standard installations.
  require 'ctioga2/git-fools-svn'
rescue LoadError => e
end
