class ObjectifiedHash
  def initialize(hash)
    @hash = hash
  end

  private

  attr_reader :hash

  def method_missing(method_name, *args, &block)
    if hash.key?(method_name.to_sym)
      hash[method_name.to_sym]
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    hash.key?(method_name.to_sym) || super
  end
end

class Foo
  def system(...)
    # Kernel#system is called
    raw.system(...)
    # (...) passes if there is no
    # raw.system
  end

  def initialize(raw)
    @raw = raw
  end

  def get_system
    system
  end

  private

  attr_reader :raw
end

class Test
  def self.run
    obj = ObjectifiedHash.new({
      system: 'system'
    })

    foo = Foo.new(obj)
    # foo.system would pass.
    # After executing foo.system, hoge.get_system also passes.
    # p foo.system
    p foo.get_system
  end
end

Test.run

