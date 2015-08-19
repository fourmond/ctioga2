# ruby.rb: interaction with user-supplied Ruby code
# copyright (c) 2014 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).


module CTioga2

  # The class in charge of the interaction with Ruby code
  class Ruby

    # Module where all instance methods declared become immediately
    # class methods.
    class MetaModule < Module

      include Math
      
      def method_added(meth)
        module_function meth
      end

    end
    
    @module = MetaModule.new
    
    def self.run_code(str)
      @module.send(:module_eval,str)
    end

    def self.run_file(file)
      Utils::open(file) do |f|
        run_code(f.read)
      end
    end
    
    def self.compute_formula(col, vals, mods = [])
      return Dobjects::Dvector.compute_formula(col, vals, [@module] + mods)
    end

    # Returns a Dobjects::MathEvaluator object to evaluate
    def self.make_evaluator(formula, vars, mods = [])
      return Dobjects::MathEvaluator.new(formula, vars.join(","),
                                         [@module] + mods)
    end

  end
end

