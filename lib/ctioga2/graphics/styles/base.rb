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
        def self.typed_attribute(symbol, type)
          sym = symbol.to_sym
          self.attr_accessor(sym)
          type = CmdArg.new(type) unless type.respond_to? :string_to_type
          @attribute_types ||= {}
          @attribute_types[sym] = type
        end

        def self.options_hash(key = "%s")
          ret = {}
          for k, v in @attribute_types
            ret[key % k] = v
          end
          return ret
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
        def set_from_hash(hash, name = "%s")
          for key_name in self.class.attributes
            hash_key = name % key_name
            if hash.key? hash_key 
              self.send("#{key_name}=", hash[hash_key])
            end
          end
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

