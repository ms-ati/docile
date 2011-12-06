require 'set'

module Docile
  class FallbackContextProxy
    BASIC_METHODS = Set[:==, :equal?, :"!", :"!=",
                        :instance_eval, :instance_variable_get, :instance_variable_set,
                        :object_id, :__send__, :__id__]

    instance_methods.each do |method|
      unless BASIC_METHODS.include?(method.to_sym)
        undef_method(method)
      end
    end

    def initialize(receiver, fallback)
      @__receiver__ = receiver
      @__fallback__ = fallback
    end

    def id
      @__receiver__.__send__(:id)
    end

    # Special case due to `Kernel#sub`'s existence
    def sub(*args, &block)
      __proxy_method__(:sub, *args, &block)
    end

    def method_missing(method, *args, &block)
      __proxy_method__(method, *args, &block)
    end

    def __proxy_method__(method, *args, &block)
      begin
        @__receiver__.__send__(method.to_sym, *args, &block)
      rescue ::NoMethodError => e
        begin
          @__fallback__.__send__(method.to_sym, *args, &block)
        rescue ::NoMethodError
          raise(e)
        end
      end
    end
  end
end