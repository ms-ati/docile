require "docile/fallback_context_proxy"

module Docile

  class ChainingFallbackContextProxy < FallbackContextProxy

    def method_missing(method, *args, &block)
      @__receiver__ = super(method, *args, &block)
    end

  end

end