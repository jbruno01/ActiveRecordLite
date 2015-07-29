class AttrAccessorObject
  def self.my_attr_accessor(*names)

    names.each do |name|
      define_method("#{name}=") do |arg|
        instance_variable_set("@#{name}", arg)
      end
    end

    names.each do |name|
      define_method(name) do
        instance_variable_get("@#{name}")
      end
    end

  end
end


class Cat
  attr_accessor :color

  def color
    @color
  end

  def color=(arg)
    @color = arg
  end
end
