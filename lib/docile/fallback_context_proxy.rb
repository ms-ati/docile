require 'set'

module Docile
  class FallbackContextProxy
    NON_PROXIED_METHODS = Set[:__send__, :object_id, :__id__, :==, :equal?,
                              :"!", :"!=", :instance_exec, :instance_variables,
                              :instance_variable_get, :instance_variable_set,
                              :remove_instance_variable]

    NON_PROXIED_INSTANCE_VARIABLES = Set[:@__receiver__, :@__fallback__]

    instance_methods.each do |method|
      undef_method(method) unless NON_PROXIED_METHODS.include?(method.to_sym)
    end

    def initialize(receiver, fallback)
      @__receiver__ = receiver
      @__fallback__ = fallback
    end

    def instance_variables
      # Ruby 1.8.x returns string names, convert to symbols for compatibility
      super.select { |v| !NON_PROXIED_INSTANCE_VARIABLES.include?(v.to_sym) }
    end

    def method_missing(method, *args, &block)
      __proxy_method__(method, *args, &block)
    end

    def __proxy_method__(method, *args, &block)
      @__receiver__.__send__(method.to_sym, *args, &block)
    rescue ::NoMethodError => e
      @__fallback__.__send__(method.to_sym, *args, &block)
    end
  end
end
