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

# For platform detection
require 'rbconfig'

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

    # Converts a number to a float while trying to stay as lenient as
    # possible
    def self.txt_to_float(txt)
      v = txt.to_f
      if v == 0.0
        return Float(txt)
      end
      return v
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

    # Quotes a string so it can be included directly within a
    # \pdfinfo statement (for instance).
    def self.tex_quote_string(str)
      return str.gsub(/([%#])|([{}~_^])|\\/) do 
        if $1
          "\\#{$1}"
        elsif $2
          "\\string#{$2}"
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

    NaturalSubdivisions = [1.0, 2.0, 5.0, 10.0]

    # Returns the closest element of the correct power of ten of
    # NaturalSubdivisions above or below the given number
    def self.closest_subdivision(x, below = true)
      fact = 10**(Math.log10(x).floor)

      normed_x = x/fact
      (NaturalSubdivisions.size()-1).times do |i|
        if normed_x == NaturalSubdivisions[i]
          return x
        end
        if (normed_x > NaturalSubdivisions[i]) && 
            (normed_x < NaturalSubdivisions[i+1])
          if below
            return NaturalSubdivisions[i]*fact
          else
            return NaturalSubdivisions[i+1]*fact
          end
        end
      end
      raise "Should not reach this !"
    end


    # Returns the smallest power of 10 within the given buffer
    # (excluding 0 or anything really close). That is, if you multiply
    # by 10 to the power what is returned, the smallest will be in the
    # range 1-10.
    def self.common_pow10(vect, method = :floor, tolerance = 1e-8)
      a = vect.abs
      a.sort!
      while (a.size > 1) && (a.first < tolerance * a.last)
        a.shift
      end

      return Math.log10(a.first).send(method)
    end


    # Transcodes the given string from all encodings into the target
    # encoding until an encoding is found in which the named file
    # exists.
    #
    # Works around encoding problems on windows.
    def self.transcode_until_found(file)
      if File.exists? file
        return file
      end
      begin                     # We wrap in a begin/rescue block for
                                # Ruby 1.8
        for e in Encoding::constants
          e = Encoding.const_get(e)
          if e.is_a? Encoding
            begin
              ts = file.encode(Encoding::default_external, e)
              if File.exists? ts
                return ts
              end
            rescue
            end
          end
        end
      rescue
      end
      return file               # But that will fail later on.
    end



    # Cross-platform way of finding an executable in the $PATH.
    #
    # This is adapted from
    # http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
    def self.which(cmd)
      return nil unless cmd
      exts = ['']
      if ENV['PATHEXT']
        exts += ENV['PATHEXT'].split(';')
      end

      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable? exe
        }
      end
      return nil
    end


    # Reliable OS detection, coming from:
    #
    # http://stackoverflow.com/questions/11784109/detecting-operating-systems-in-ruby
    def self.os
      host_os = RbConfig::CONFIG['host_os']
      case host_os
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        :windows
      when /darwin|mac os/
        :macosx
      when /linux/
        :linux
      when /solaris|bsd/
        :unix
      else
        warn {"Unknown os: #{host_os.inspect}"}
        :unknown
      end
    end


    # Cluster a series of objects by the values returned by the given
    # funcall. It returns an array of arrays where the elements are in
    # the same order, and in each sub-array, the functions all return
    # the same value
    #
    # @todo with block too ?
    def self.cluster_by_value(list, funcall)
      if list.size == 0
        return []
      end
      ret = [ [list[0]] ]
      cur = ret[0]
      last = cur.first.send(funcall)

      for o in list[1..-1]
        val = o.send(funcall)
        if last == val
          cur << o
        else
          cur = [o]
          ret << cur
          last = val
        end
      end

      return ret
     end


    # Returns a hash value -> [elements] in which the elements are in
    # the same order
    def self.sort_by_value(list, funcall)
      ret = {}
      
      for el in list
        val = el.send(funcall)
        ret[val] ||= []

        ret[val] << el
      end
      return ret
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
      @regexp_kv = []
    end

    # Sets the key to the given value
    def []=(key, value)
      if Regexp === key
        @regexp_kv <<  [key, value]
      else
        @hash[key] = value
      end
    end

    # Gets the value corresponding to the key, using pattern matching
    # should the need arise.
    #
    # If there are several regexps matching a given key, the
    # implementation guarantees that the last one to have been
    # inserted that matches is taken
    def [](key)
      if @hash.key?(key)
        return @hash[key]
      else
        for k,v in @regexp_kv.reverse
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

######################################################################
# Now come a few functions that add to ruby's standard classes or
# modules

module Math

  # The absolute value, but in a more easy to use way
  def abs(x)
    return x.abs
  end
end



# Here, we define an additional function in the Hash class: without
class Hash

  # Returns a copy of the hash without the given keys
  def without(*args)
    ret = self.dup
    for a in args.flatten
      ret.delete(a)
    end
    return ret
  end

  # Renames the given key
  def rename_key(old, new)
    self[new] = self[old]
    self.delete(old)
  end

end


class String
  # Splits a string into substrings at the given regexp, but only if
  # the splitting occurs at top-level with respect to parentheses.
  def split_at_toplevel(regexp)
    # Groups
    grps = {} 
    
    sz = 0
    s = self.dup
    while true
      s.gsub!(/\([^()]+\)/) do |x|
        idx = grps.size
        rep = "__#{idx}__"
        grps[rep] = x
        rep
      end
      if sz == grps.size
        break
      else
        sz = grps.size
      end
    end
    
    splitted = s.split(regexp)
    
    while grps.size > 0
      for s in splitted
        s.gsub!(/__\d+__/) do |x|
          rep = grps[x]
          grps.delete(x)
          rep
        end
      end
    end
    return splitted
  end
end

begin
  # This is a dirty hack in order to ensure that the SVN revision
  # information is kept up-to-date even when using git-svn. This
  # file is not present in standard installations.
  require 'ctioga2/git-fools-svn'
rescue LoadError => e
end

