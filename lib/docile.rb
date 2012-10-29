require "docile/version"
require "docile/fallback_context_proxy"

module Docile
  # Executes a block in the context of an object whose interface represents a DSL.
  #
  # Example of using an Array as a DSL:
  #
  #     Docile.dsl_eval [] do
  #       push 1
  #       push 2
  #       pop
  #       push 3
  #     end
  #     #=> [1, 3]
  #
  # @param dsl   [Object] an object whose methods represent a DSL
  # @param block [Proc]   a block to execute in the DSL context
  # @return      [Object] the dsl object, after execution of the block
  def dsl_eval(dsl, &block)
    block_context = eval("self", block.binding)
    proxy_context = FallbackContextProxy.new(dsl, block_context)
    begin
      block_context.instance_variables.each { |ivar| proxy_context.instance_variable_set(ivar, block_context.instance_variable_get(ivar)) }
      proxy_context.instance_eval(&block)
    ensure
      block_context.instance_variables.each { |ivar| block_context.instance_variable_set(ivar, proxy_context.instance_variable_get(ivar)) }
    end
    dsl
  end
  module_function :dsl_eval
end
