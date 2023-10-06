# frozen_string_literal: true

require "spec_helper"

# TODO: Factor single spec file into multiple specs
# rubocop:disable RSpec/MultipleDescribes
describe Docile do
  describe ".dsl_eval" do
    before :each do
      stub_const("Pizza",
                 Struct.new(:cheese, :pepperoni, :bacon, :sauce))

      stub_const("PizzaBuilder", Class.new do
        # rubocop:disable all
        def cheese(v=true);    @cheese    = v; end
        def pepperoni(v=true); @pepperoni = v; end
        def bacon(v=true);     @bacon     = v; end
        def sauce(v=nil);      @sauce     = v; end
        # rubocop:enable all

        def build
          Pizza.new(!!@cheese, !!@pepperoni, !!@bacon, @sauce)
        end
      end)

      stub_const("InnerDSL", Class.new do
        def initialize
          @b = "b"
        end

        attr_accessor :b

        def c
          "inner c"
        end
      end)

      stub_const("OuterDSL", Class.new do
        def initialize
          @a = "a"
        end

        attr_accessor :a

        def c
          "outer c"
        end

        def inner(&block)
          Docile.dsl_eval(InnerDSL.new, &block)
        end

        def inner_with_params(param, &block)
          Docile.dsl_eval(InnerDSL.new, param, :foo, &block)
        end
      end)
    end

    def outer(&block)
      Docile.dsl_eval(OuterDSL.new, &block)
    end

    context "when DSL context object is an Array" do
      let(:array) { [] }
      let!(:result) { execute_dsl_against_array }

      def execute_dsl_against_array
        Docile.dsl_eval(array) do
          push 1
          push 2
          pop
          push 3
        end
      end

      it "executes the block against the DSL context object" do
        expect(array).to eq([1, 3])
      end

      it "returns the DSL object after executing block against it" do
        expect(result).to eq(array)
      end

      it "doesn't proxy #__id__" do
        described_class.dsl_eval(array) do
          expect(__id__).not_to eq(array.__id__)
        end
      end

      it "raises NoMethodError if DSL object doesn't implement the method" do
        expect do
          described_class.dsl_eval(array) { no_such_method }
        end.to raise_error(NoMethodError)
      end
    end

    context "when DSL context object is a Builder pattern" do
      let(:builder) { PizzaBuilder.new }
      let(:result) { execute_dsl_against_builder_and_call_build }

      def execute_dsl_against_builder_and_call_build
        @sauce = :extra
        Docile.dsl_eval(builder) do
          bacon
          cheese
          sauce @sauce # rubocop:disable RSpec/InstanceVariable
        end.build
      end

      it "returns correctly built object" do
        expect(result).to eq(Pizza.new(true, false, true, :extra))
      end
    end

    context "when given parameters for the DSL block" do
      def parameterized(*args, &block)
        Docile.dsl_eval(OuterDSL.new, *args, &block)
      end

      it "passes parameters to the block" do
        parameterized(1, 2, 3) do |x, y, z|
          expect(x).to eq(1)
          expect(y).to eq(2)
          expect(z).to eq(3)
        end
      end

      it "finds parameters before methods" do
        parameterized(1) { |a| expect(a).to eq(1) }
      end

      it "find outer dsl parameters in inner dsl scope" do
        parameterized(1, 2, 3) do |a, b, c|
          inner_with_params(c) do |d, e|
            expect(a).to eq(1)
            expect(b).to eq(2)
            expect(c).to eq(3)
            expect(d).to eq(c)
            expect(e).to eq(:foo)
          end
        end
      end
    end

    context "when block's context has helper methods which call DSL methods" do
      subject { context.method(:factorial_as_dsl_against_array) }

      let(:context) do
        class_block_context_with_helper_methods.new(array_as_dsl)
      end

      let(:array_as_dsl) { [1, 1] }

      let(:class_block_context_with_helper_methods) do
        Class.new do
          def initialize(array_as_dsl)
            @array_as_dsl = array_as_dsl
          end

          # Classic dynamic programming factorial, using the methods of {Array}
          # as a DSL to implement it, via helper methods {#calculate_factorials}
          # and {#save_factorials} which are defined in this class, so therefore
          # outside the block.
          def factorial_as_dsl_against_array(num)
            Docile.dsl_eval(@array_as_dsl) { calculate_factorials(num) }.last
          end

          # Uses the helper method {#save_factorials} below.
          def calculate_factorials(num)
            (2..num).each { |i| save_factorial(i) }
          end

          # Uses the methods {Array#push} and {Array#at} as a DSL from a helper
          # method defined in the block's context. Successfully calling this
          # proves that we can find helper methods from outside the block, and
          # then find DSL methods from inside those helper methods.
          def save_factorial(num)
            push(num * at(num - 1))
          end
        end
      end

      it "finds DSL methods within helper method defined in block's context" do
        # see https://en.wikipedia.org/wiki/Factorial
        # rubocop:disable Layout/ExtraSpacing
        [
          [0,                  1],
          [1,                  1],
          [2,                  2],
          [3,                  6],
          [4,                 24],
          [5,                120],
          [6,                720],
          [7,              5_040],
          [8,             40_320],
          [9,            362_880],
          [10,         3_628_800],
          [11,        39_916_800],
          [12,       479_001_600],
          [13,     6_227_020_800],
          [14,    87_178_291_200],
          [15, 1_307_674_368_000]
        ].each do |n, expected_factorial|
          array_as_dsl.replace([1, 1])
          expect(subject.call(n)).to eq expected_factorial
        end
        # rubocop:enable Layout/ExtraSpacing
      end

      it "removes fallback instrumentation from the DSL object after block" do
        expect { subject.call(5) }.
          not_to change { context.respond_to?(:method_missing) }.
          from(false)
      end

      it "removes method to remove fallbacl from the DSL object after block" do
        expect { subject.call(5) }.
          not_to change { context.respond_to?(:__docile_undo_fallback__) }.
          from(false)
      end

      context "when helper methods call methods that are undefined" do
        let(:array_as_dsl) { "not an array" }

        it "raises NoMethodError" do
          expect { subject.call(5) }.
            to raise_error(NoMethodError, /method `at' /)
        end

        it "removes fallback instrumentation from the DSL object after block" do
          expect { subject.call(5) rescue nil }. # rubocop:disable Style/RescueModifier
            not_to change { context.respond_to?(:method_missing) }.
            from(false)
        end
      end
    end

    context "when DSL have NoMethod error inside" do
      let(:class_dsl_with_no_method) do
        Class.new do
          def push_element
            nil.push(1)
          end
        end
      end

      it "raise NoMethodError error from nil" do
        described_class.dsl_eval(class_dsl_with_no_method.new) do
          expect { push_element }.
            to raise_error(
              NoMethodError,
              /undefined method `push' (for|on) nil/
            )
        end
      end
    end

    context "when DSL blocks are nested" do
      describe "method lookup" do
        # rubocop:disable Style/SingleLineMethods
        it "finds method of outer dsl in outer dsl scope" do
          outer { expect(a).to eq("a") }
          outer { inner {}; expect(c).to eq("outer c") } # rubocop:disable Style/Semicolon
        end

        it "finds method of inner dsl in inner dsl scope" do
          outer { inner { expect(b).to eq("b") } }
          outer { inner { expect(c).to eq("inner c") } }
        end

        it "finds method of outer dsl in inner dsl scope" do
          outer { inner { expect(a).to eq("a") } }
        end

        it "finds method of block's context in outer dsl scope" do
          def d; "d"; end
          outer { expect(d).to eq("d") }
        end

        it "finds method of block's context in inner dsl scope" do
          def d; "d"; end
          outer { inner { expect(d).to eq("d") } }
        end

        it "finds method of outer dsl in preference to block context" do
          def a; "not a"; end
          outer { expect(a).to eq("a") }
          outer { inner { expect(a).to eq("a") } }
        end
        # rubocop:enable Style/SingleLineMethods
      end

      describe "local variable lookup" do
        it "finds local variable from block context in outer dsl scope" do
          foo = "foo"
          outer { expect(foo).to eq("foo") }
        end

        it "finds local variable from block definition in inner dsl scope" do
          bar = "bar"
          outer { inner { expect(bar).to eq("bar") } }
        end
      end

      describe "instance variable lookup" do
        # rubocop:disable RSpec/InstanceVariable
        it "finds instance variable from block definition in outer dsl scope" do
          @iv1 = "iv1"
          outer { expect(@iv1).to eq("iv1") }
        end

        it "proxies instance variable assignments in block in outer dsl scope "\
           "back into block's context" do
          @iv1 = "foo"
          outer { @iv1 = "bar" }
          expect(@iv1).to eq("bar")
        end

        it "finds instance variable from block definition in inner dsl scope" do
          @iv2 = "iv2"
          outer { inner { expect(@iv2).to eq("iv2") } }
        end

        it "proxies instance variable assignments in block in inner dsl scope "\
           "back into block's context" do
          @iv2 = "foo"
          outer { inner { @iv2 = "bar" } }
          expect(@iv2).to eq("bar")
        end
        # rubocop:enable RSpec/InstanceVariable
      end

      describe "identity of 'self' inside nested dsl blocks" do
        # see https://github.com/ms-ati/docile/issues/31
        subject do
          identified_selves = {}

          outer do
            identified_selves[:a] = self

            inner do
              identified_selves[:b] = self
            end

            identified_selves[:c] = self
          end

          identified_selves
        end

        it "identifies self inside outer dsl block" do
          expect(subject[:a]).to be_instance_of(OuterDSL)
        end

        it "replaces self inside inner dsl block" do
          expect(subject[:b]).to be_instance_of(InnerDSL)
        end

        it "restores self to the outer dsl object after the inner dsl block" do
          expect(subject[:c]).to be_instance_of(OuterDSL)
          expect(subject[:c]).to be(subject[:a])
        end
      end
    end

    context "when DSL context object is a Dispatch pattern" do
      let(:class_message_dispatcher) do
        Class.new do
          def initialize
            @responders = {}
          end

          def add_responder(path, &block)
            @responders[path] = block
          end

          def dispatch(path, request)
            Docile.
              dsl_eval(class_dispatch_scope.new, request, &@responders[path])
          end

          def class_dispatch_scope
            Class.new do
              def params
                { a: 1, b: 2, c: 3 }
              end
            end
          end
        end
      end

      let(:message_dispatcher_instance) do
        class_message_dispatcher.new
      end

      def respond(path, &block)
        message_dispatcher_instance.add_responder(path, &block)
      end

      def send_request(path, request)
        message_dispatcher_instance.dispatch(path, request)
      end

      # rubocop:disable RSpec/InstanceVariable
      it "dispatches correctly" do
        @first = @second = nil

        respond "/path" do |request|
          @first = request
        end

        respond "/new_bike" do |bike|
          @second = "Got a new #{bike}"
        end

        def third(val)
          "Got a #{val}"
        end

        respond "/third" do |arg|
          expect(third(arg)).to eq("Got a third thing")
        end

        fourth = nil

        respond "/params" do |arg|
          fourth = params[arg]
        end

        send_request "/path", 1
        send_request "/new_bike", "ten speed"
        send_request "/third", "third thing"
        send_request "/params", :b

        expect(@first).to eq(1)
        expect(@second).to eq("Got a new ten speed")
        expect(fourth).to eq(2)
      end
      # rubocop:enable RSpec/InstanceVariable
    end

    context "when DSL context object is same as the block's context object" do
      let(:class_context_same_as_block_context) do
        Class.new do
          def foo(val = nil)
            @foo = val if val
            @foo
          end

          def bar(val = nil)
            @bar = val if val
            @bar
          end

          def dsl_eval(block)
            Docile.dsl_eval(self, &block)
          end

          def dsl_eval_string(string)
            block = binding.eval("proc { #{string} }") # rubocop:disable all
            dsl_eval(block)
          end
        end
      end

      let(:dsl) { class_context_same_as_block_context.new }

      it "calls DSL methods and sets state on the DSL context object" do
        dsl.dsl_eval_string("foo 0; bar 1")
        expect(dsl.foo).to eq(0)
        expect(dsl.bar).to eq(1)
      end

      context "when the DSL object is frozen" do
        it "can call non-mutative code without raising an exception" do
          expect { dsl.freeze.dsl_eval_string("1 + 2") }.not_to raise_error
        end
      end
    end

    context "when NoMethodError is raised" do
      specify "#backtrace doesn't include path to Docile's sources" do
        described_class.dsl_eval(Object.new) { foo }
      rescue NoMethodError => e
        expect(e.backtrace).not_to include(match(%r{/lib/docile/}))
      end

      specify "#backtrace_locations doesn't include path to Docile's sources" do
        described_class.dsl_eval(Object.new) { foo }
      rescue NoMethodError => e
        expect(e.backtrace_locations.map(&:absolute_path)).
          not_to include(match(%r{/lib/docile/}))
      end
    end

    context "when a DSL method has a keyword argument" do
      let(:class_with_method_with_keyword_arg) do
        Class.new do
          attr_reader :v0, :v1, :v2

          def set(arg, kw1:, kw2:)
            @v0 = arg
            @v1 = kw1
            @v2 = kw2
          end
        end
      end

      let(:dsl) { class_with_method_with_keyword_arg.new }

      it "calls such DSL methods with no stderr output" do
        # This is to check warnings related to keyword argument is not output.
        # See: https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/
        expect do
          described_class.dsl_eval(dsl) { set(0, kw2: 2, kw1: 1) }
        end.
          not_to output.to_stderr

        expect(dsl.v0).to eq 0
        expect(dsl.v1).to eq 1
        expect(dsl.v2).to eq 2
      end
    end

    context "when a DSL method has a double splat" do
      let(:class_with_method_with_double_splat) do
        Class.new do
          attr_reader :arguments, :options

          def configure(*arguments, **options)
            @arguments = arguments.dup
            @options = options.dup
          end
        end
      end

      let(:dsl) { class_with_method_with_double_splat.new }

      it "correctly passes keyword arguments" do
        described_class.dsl_eval(dsl) { configure(1, a: 1) }

        expect(dsl.arguments).to eq [1]
        expect(dsl.options).to eq({ a: 1 })
      end

      it "correctly passes hash arguments" do
        described_class.dsl_eval(dsl) { configure(1, { a: 1 }) }

        # TruffleRuby 22.0.0.2 has RUBY_VERSION of 3.0.2, but behaves as 2.x
        if RUBY_VERSION >= "3.0.0" && RUBY_ENGINE != "truffleruby"
          expect(dsl.arguments).to eq [1, { a: 1 }]
          expect(dsl.options).to eq({})
        else
          expect(dsl.arguments).to eq [1]
          expect(dsl.options).to eq({ a: 1 })
        end
      end
    end
  end

  describe ".dsl_eval_with_block_return" do
    let(:array) { [] }
    let!(:result) { execute_dsl_against_array }

    def execute_dsl_against_array
      Docile.dsl_eval_with_block_return(array) do
        push 1
        push 2
        pop
        push 3
        "Return me!"
      end
    end

    it "executes the block against the DSL context object" do
      expect(array).to eq([1, 3])
    end

    it "returns the block's return value" do
      expect(result).to eq("Return me!")
    end
  end

  describe ".dsl_eval_immutable" do
    context "when DSL context object is a frozen String" do
      let(:original) { "I'm immutable!".freeze } # rubocop:disable Style/RedundantFreeze
      let!(:result) { execute_non_mutating_dsl_against_string }

      def execute_non_mutating_dsl_against_string
        Docile.dsl_eval_immutable(original) do
          reverse
          upcase
        end
      end

      it "doesn't modify the original string" do
        expect(original).to eq("I'm immutable!")
      end

      it "chains the commands in the block against the DSL context object" do
        expect(result).to eq("!ELBATUMMI M'I")
      end
    end

    context "when DSL context object is a number" do
      let(:original) { 84.5 }
      let!(:result) { execute_non_mutating_dsl_against_number }

      def execute_non_mutating_dsl_against_number
        Docile.dsl_eval_immutable(original) do
          fdiv(2)
          floor
        end
      end

      it "chains the commands in the block against the DSL context object" do
        expect(result).to eq(42)
      end
    end
  end
end

describe Docile::FallbackContextProxy do
  describe "#instance_variables" do
    subject { create_fcp_and_set_one_instance_variable.instance_variables }

    let(:expected_type_of_names) { type_of_ivar_names_on_this_ruby }
    let(:actual_type_of_names) { subject.first.class }
    let(:excluded) do
      Docile::FallbackContextProxy::NON_PROXIED_INSTANCE_VARIABLES
    end

    def create_fcp_and_set_one_instance_variable
      fcp = Docile::FallbackContextProxy.new(nil, nil)
      fcp.instance_variable_set(:@foo, "foo")
      fcp
    end

    def type_of_ivar_names_on_this_ruby
      @a = 1
      instance_variables.first.class
    end

    it "returns proxied instance variables" do
      expect(subject.map(&:to_sym)).to include(:@foo)
    end

    it "doesn't return non-proxied instance variables" do
      expect(subject.map(&:to_sym)).not_to include(*excluded)
    end

    it "preserves the type (String or Symbol) of names on this ruby version" do
      expect(actual_type_of_names).to eq(expected_type_of_names)
    end
  end
end
