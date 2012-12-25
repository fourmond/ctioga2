# base.rb: the base of style objects
# copyright (c) 2009, 2012 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'ctioga2/log'

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    # All the styles
    module Styles

      # This style is the base class of a series of style objects that
      # share one common feature: all their attributes can be set
      # using the set_from_hash function.
      #
      # \todo a basic MetaBuilder::Type should be associated to each
      # attribute ??? This would allow the class to provide a
      # parameters_hash method to allow commands to directly pull those.
      class BasicStyle

        OldAttrAccessor = method(:attr_accessor)

        # This redefinition of attr_accessor allows to track for the
        # names of the attributes, while still showing them up
        # properly documented in rdoc.
        def self.attr_accessor(symbol)
          @attributes ||= []
          @attributes << symbol
          OldAttrAccessor.call(symbol)
          # cl = caller()
          # if not cl[0] =~ /typed_attribute/
          #   puts "old-style attribute: #{cl[0]}"
          # end
        end

        # Returns the list of attributes.
        def self.attributes
          return ( @attributes || [] ) + 
            if superclass.respond_to?(:attributes)
              superclass.attributes
            else
              []
            end
        end

        # This function should be the main way now of declaring
        # attributes, as it allows one to automatically generate an
        # options hash for Command
        #
        # @todo There may be a reason to make some of the attributes
        # private to some extent ?
        #
        # @todo Provide a function to make attributes "aliases" of
        # others (but just on the hash side of the things)
        def self.typed_attribute(symbol, type)
          sym = symbol.to_sym
          self.attr_accessor(sym)
          type = CmdArg.new(type) unless type.respond_to? :string_to_type
          @attribute_types ||= {}
          @attribute_types[sym] = type
        end

        # Defines an accessor for an attribute which is a BasicStyle
        # subclass in itself.
        #
        # _format_ is the thing fed to the subclass for the
        # _from_hash_ function.
        def self.sub_style(symbol, cls, fmt = nil)
          @sub_styles ||= []    # A list of [symbol, cls, fmt]
          
          if ! fmt
            fmt = "#{symbol.to_s}_%s"
          end
          
          @sub_styles << [symbol, cls, fmt]
          # Define the accessor
          OldAttrAccessor.call(symbol)
        end

        def self.options_hash(key = "%s")
          ret = if superclass.respond_to?(:options_hash)
                  superclass.options_hash(key)
                else
                  {}
                end

          if @attribute_types   # Not always present
            for k, v in @attribute_types
              ret[key % k] = v
            end
          end
            
          if @sub_styles        # Not always present too
            for sub in @sub_styles
              sym, cls, fmt = *sub
              ret.merge!(cls.options_hash(fmt))
            end
          end
          return ret
        end

        def self.sub_styles
          return @sub_styles
        end

        # Sets the values of the attributes from the given
        # _hash_. Keys are looked under the form of
        # 
        #  name % key_name
        #  
        # where _key_name_ takes all the values of the attributes.
        #
        # Unspecified attributes are not removed from the
        # object. Extra keys are silently ignored.
        #
        # @todo Maybe there should be a way to detect extra attributes ?
        #
        # This function returns the number of properties that were
        # effectively set (including those set in sub-styles)
        def set_from_hash(hash, name = "%s")
          nb_set = 0
          for key_name in self.class.attributes
            hash_key = name % key_name
            if hash.key? hash_key 
              self.send("#{key_name}=", hash[hash_key])
              nb_set += 1
            end
          end

          if self.class.sub_styles
            for sub in self.class.sub_styles
              sym, cls, fmt = *sub
              cur_var = self.send(sym)
              if ! cur_var        # Create if not present
                cur_var = cls.new
                set_after = true
              end
              nb = cur_var.set_from_hash(hash, fmt)
              if nb > 0 and set_after
                self.send("#{sym}=", cur_var)
              end
              nb_set += nb
            end
          end
          return nb_set
            
        end

        # Creates a new object from a hash specification, just as in
        # #set_from_hash.
        def self.from_hash(hash, name = "%s")
          obj = self.new
          obj.set_from_hash(hash, name)
          return obj
        end

        # We define instance_variable_defined? if Ruby does not have
        # it... Old Ruby 1.8 versions don't - that is the case for
        # those on MacOS.
        if not self.respond_to?(:instance_variable_defined?)
          def instance_variable_defined?(iv)
            a = instance_variables.index(iv)
            if a && a >= 0 
              return true
            else
              return false
            end
          end
        end

        # Converts to a hash. Does the reverse of #set_from_hash.
        def to_hash(name = "%s")
          retval = {}
          for attr in self.class.attributes
            if instance_variable_defined?("@#{attr}")
              retval[name % attr] = instance_variable_get("@#{attr}")
            end
          end
          return retval
        end

        # Updates information from another object.
        def update_from_other(other_object)
          set_from_hash(other_object.to_hash)
        end

      end
    end
  end
end

