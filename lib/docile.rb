require "docile/version"
require "docile/fallback_context_proxy"
require "docile/chaining_fallback_context_proxy"

# Docile keeps your Ruby DSLs tame and well-behaved
# @see http://ms-ati.github.com/docile/
module Docile
  # Execute a block in the context of an object whose methods represent the
  # commands in a DSL.
  #
  # @note Use with an *imperative* DSL (commands modify the context object)
  #
  # Use this method to execute an *imperative* DSL, which means that:
  #
  #   1. each command mutates the state of the DSL context object
  #   2. the return values of the commands are ignored
  #
  # @example Use a String as a DSL
  #   Docile.dsl_eval("Hello, world!") do
  #     reverse!
  #     upcase!
  #   end
  #   #=> "!DLROW ,OLLEH"
  #
  # @example Use an Array as a DSL
  #   Docile.dsl_eval([]) do
  #     push 1
  #     push 2
  #     pop
  #     push 3
  #   end
  #   #=> [1, 3]
  #
  # @param dsl   [Object] context object whose methods make up the DSL
  # @param args  [Array]  arguments to be passed to the block
  # @yield                the block of DSL commands to be executed against the
  #                         `dsl` context object
  # @return      [Object] the `dsl` context object after executing the block
  def dsl_eval(dsl, *args, &block)
    block_context = eval("self", block.binding)
    proxy_context = FallbackContextProxy.new(dsl, block_context)
    begin
      block_context.instance_variables.each do |ivar|
        value_from_block = block_context.instance_variable_get(ivar)
        proxy_context.instance_variable_set(ivar, value_from_block)
      end
      proxy_context.instance_exec(*args, &block)
    ensure
      block_context.instance_variables.each do |ivar|
        value_from_dsl_proxy = proxy_context.instance_variable_get(ivar)
        block_context.instance_variable_set(ivar, value_from_dsl_proxy)
      end
    end
    dsl
  end
  module_function :dsl_eval

  def dsl_eval_immutable(dsl, *args, &block)
    block_context = eval("self", block.binding)
    proxy_context = ChainingFallbackContextProxy.new(dsl, block_context)
    begin
      block_context.instance_variables.each do |ivar|
        value_from_block = block_context.instance_variable_get(ivar)
        proxy_context.instance_variable_set(ivar, value_from_block)
      end
      proxy_context.instance_exec(*args, &block)
    ensure
      block_context.instance_variables.each do |ivar|
        value_from_dsl_proxy = proxy_context.instance_variable_get(ivar)
        block_context.instance_variable_set(ivar, value_from_dsl_proxy)
      end
    end
  end
  module_function :dsl_eval_immutable
end
