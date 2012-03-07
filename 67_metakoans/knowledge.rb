class Module
  def attribute name, &blk
    
    name, default = name.is_a?(Hash) ? name.to_a.first : [name, nil]
    
    ivar = "@#{name}"
    
    define_method name do
      if instance_variables.include? ivar.to_sym #symbols in 1.9
        instance_variable_get ivar
      else
        blk ? instance_eval(&blk) : default
      end
    end
    
    define_method "#{name}?" do
      !!__send__(name)
    end
    
    define_method "#{name}=" do |val|
      instance_variable_set ivar, val
    end
  end
end