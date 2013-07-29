require "docile/version"
require "docile/fallback_context_proxy"
require "docile/chaining_fallback_context_proxy"

# Docile keeps your Ruby DSLs tame and well-behaved
module Docile
  # Execute a block in the context of an object whose methods represent the
  # commands in a DSL.
  #
  # @note Use with an *imperative* DSL (commands modify the context object)
  #
  # Use this method to execute an *imperative* DSL, which means that:
  #
  #   1. Each command mutates the state of the DSL context object
  #   2. The return value of each command is ignored
  #   3. The final return value is the original context object
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
    exec_in_proxy_context(dsl, FallbackContextProxy, *args, &block)
    dsl
  end
  module_function :dsl_eval

  # Execute a block in the context of an immutable object whose methods,
  # and the methods of their return values, represent the commands in a DSL.
  #
  # @note Use with a *functional* DSL (commands return successor
  #       context objects)
  #
  # Use this method to execute a *functional* DSL, which means that:
  #
  #   1. The original DSL context object is never mutated
  #   2. Each command returns the next DSL context object
  #   3. The final return value is the value returned by the last command
  #
  # @example Use a String as a DSL
  #   Docile.dsl_eval_immutable("Hello, world!") do
  #     reverse
  #     upcase
  #   end
  #   #=> "!DLROW ,OLLEH"
  #
  # @example Use a Float as a DSL
  #   Docile.dsl_eval_immutable(84.5) do
  #     fdiv(2)
  #     floor
  #   end
  #   #=> 42
  #
  # @param dsl   [Object] immutable context object whose methods make up the
  #                       initial DSL
  # @param args  [Array]  arguments to be passed to the block
  # @yield                the block of DSL commands to be executed against the
  #                         `dsl` context object and successor return values
  # @return      [Object] the return value of the final command in the block
  def dsl_eval_immutable(dsl, *args, &block)
    exec_in_proxy_context(dsl, ChainingFallbackContextProxy, *args, &block)
  end
  module_function :dsl_eval_immutable

  private

  # @api private
  #
  # Execute a block in the context of an object whose methods represent the
  # commands in a DSL, using a specific proxy class.
  #
  # @param dsl        [Object] context object whose methods make up the
  #                            (initial) DSL
  # @param proxy_type [Class]  class to instantiate as the proxy context
  # @param args       [Array]  arguments to be passed to the block
  # @yield                     the block of DSL commands to be executed
  # @return           [Object] the return value of the block
  def exec_in_proxy_context(dsl, proxy_type, *args, &block)
    block_context = eval("self", block.binding)
    proxy_context = proxy_type.new(dsl, proxy_type.new(dsl, block_context))
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
  module_function :exec_in_proxy_context
end
