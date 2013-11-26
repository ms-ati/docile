require 'spec_helper'

describe Docile do

  describe '.dsl_eval' do

    context 'when DSL context object is an Array' do
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

      it 'executes the block against the DSL context object' do
         array.should == [1, 3]
      end

      it 'returns the DSL object after executing block against it' do
         result.should == array
      end

      it "doesn't proxy #__id__" do
        Docile.dsl_eval(array) { __id__.should_not == array.__id__ }
      end

      it "raises NoMethodError if the DSL object doesn't implement the method" do
        expect { Docile.dsl_eval(array) { no_such_method } }.to raise_error(NoMethodError)
      end
    end

    Pizza = Struct.new(:cheese, :pepperoni, :bacon, :sauce)

    class PizzaBuilder
      def cheese(v=true);    @cheese    = v; end
      def pepperoni(v=true); @pepperoni = v; end
      def bacon(v=true);     @bacon     = v; end
      def sauce(v=nil);      @sauce     = v; end
      def build
        Pizza.new(!!@cheese, !!@pepperoni, !!@bacon, @sauce)
      end
    end

    context 'when DSL context object is a Builder pattern' do
      let(:builder) { PizzaBuilder.new }
      let(:result) { execute_dsl_against_builder_and_call_build }

      def execute_dsl_against_builder_and_call_build
        @sauce = :extra
        Docile.dsl_eval(builder) do
          bacon
          cheese
          sauce @sauce
        end.build
      end

      it 'returns correctly built object' do
        result.should == Pizza.new(true, false, true, :extra)
      end
    end

    class InnerDSL
      def initialize; @b = 'b'; end
      attr_accessor :b
    end

    class OuterDSL
      def initialize; @a = 'a'; end
      attr_accessor :a

      def inner(&block)
        Docile.dsl_eval(InnerDSL.new, &block)
      end

      def inner_with_params(param, &block)
        Docile.dsl_eval(InnerDSL.new, param, :foo, &block)
      end
    end

    def outer(&block)
      Docile.dsl_eval(OuterDSL.new, &block)
    end

    context 'when given parameters for the DSL block' do
      def parameterized(*args, &block)
        Docile.dsl_eval(OuterDSL.new, *args, &block)
      end

      it 'passes parameters to the block' do
        parameterized(1,2,3) do |x,y,z|
          x.should == 1
          y.should == 2
          z.should == 3
        end
      end

      it 'finds parameters before methods' do
        parameterized(1) { |a| a.should == 1 }
      end

      it 'find outer dsl parameters in inner dsl scope' do
        parameterized(1,2,3) do |a,b,c|
          inner_with_params(c) do |d,e|
            a.should == 1
            b.should == 2
            c.should == 3
            d.should == c
            e.should == :foo
          end
        end
      end
    end

    context 'when DSL blocks are nested' do

      context 'method lookup' do
        it 'finds method of outer dsl in outer dsl scope' do
          outer { a.should == 'a' }
        end

        it 'finds method of inner dsl in inner dsl scope' do
          outer { inner { b.should == 'b' } }
        end

        it 'finds method of outer dsl in inner dsl scope' do
          outer { inner { a.should == 'a' } }
        end

        it "finds method of block's context in outer dsl scope" do
          def c; 'c'; end
          outer { c.should == 'c' }
        end

        it "finds method of block's context in inner dsl scope" do
          def c; 'c'; end
          outer { inner { c.should == 'c' } }
        end

        it 'finds method of outer dsl in preference to block context' do
          def a; 'not a'; end
          outer { a.should == 'a' }
          outer { inner { a.should == 'a' } }
        end
      end

      context 'local variable lookup' do
        it 'finds local variable from block context in outer dsl scope' do
          foo = 'foo'
          outer { foo.should == 'foo' }
        end

        it 'finds local variable from block definition in inner dsl scope' do
          bar = 'bar'
          outer { inner { bar.should == 'bar' } }
        end
      end

      context 'instance variable lookup' do
        it 'finds instance variable from block definition in outer dsl scope' do
          @iv1 = 'iv1'; outer { @iv1.should == 'iv1' }
        end

        it "proxies instance variable assignments in block in outer dsl scope back into block's context" do
          @iv1 = 'foo'; outer { @iv1 = 'bar' }; @iv1.should == 'bar'
        end

        it 'finds instance variable from block definition in inner dsl scope' do
          @iv2 = 'iv2'; outer { inner { @iv2.should == 'iv2' } }
        end

        it "proxies instance variable assignments in block in inner dsl scope back into block's context" do
          @iv2 = 'foo'; outer { inner { @iv2 = 'bar' } }; @iv2.should == 'bar'
        end
      end

    end

    context 'when DSL context object is a Dispatch pattern' do
      class DispatchScope
        def params
          { :a => 1, :b => 2, :c => 3 }
        end
      end

      class MessageDispatch
        include Singleton

        def initialize
          @responders = {}
        end

        def add_responder path, &block
          @responders[path] = block
        end

        def dispatch path, request
          Docile.dsl_eval(DispatchScope.new, request, &@responders[path])
        end
      end

      def respond(path, &block)
        MessageDispatch.instance.add_responder(path, &block)
      end

      def send_request(path, request)
        MessageDispatch.instance.dispatch(path, request)
      end

      it 'dispatches correctly' do
        @first = @second = nil

        respond '/path' do |request|
          @first = request
        end

        respond '/new_bike' do |bike|
          @second = "Got a new #{bike}"
        end

        def x(y) ; "Got a #{y}"; end
        respond '/third' do |third|
          x(third).should == 'Got a third thing'
        end

        fourth = nil
        respond '/params' do |arg|
          fourth = params[arg]
        end

        send_request '/path', 1
        send_request '/new_bike', 'ten speed'
        send_request '/third', 'third thing'
        send_request '/params', :b

        @first.should == 1
        @second.should == 'Got a new ten speed'
        fourth.should == 2
      end

    end

  end

  describe '.dsl_eval_immutable' do

    context 'when DSL context object is a frozen String' do
      let(:original) { "I'm immutable!".freeze }
      let!(:result) { execute_non_mutating_dsl_against_string }

      def execute_non_mutating_dsl_against_string
        Docile.dsl_eval_immutable(original) do
          reverse
          upcase
        end
      end

      it "doesn't modify the original string" do
         original.should == "I'm immutable!"
      end

      it 'chains the commands in the block against the DSL context object' do
         result.should == "!ELBATUMMI M'I"
      end
    end

    context 'when DSL context object is a number' do
      let(:original) { 84.5 }
      let!(:result) { execute_non_mutating_dsl_against_number }

      def execute_non_mutating_dsl_against_number
        Docile.dsl_eval_immutable(original) do
          fdiv(2)
          floor
        end
      end

      it 'chains the commands in the block against the DSL context object' do
         result.should == 42
      end
    end
  end

end

describe Docile::FallbackContextProxy do

  describe "#instance_variables" do
    subject { create_fcp_and_set_one_instance_variable.instance_variables }
    let(:expected_type_of_names) { type_of_ivar_names_on_this_ruby }
    let(:actual_type_of_names) { subject.first.class }
    let(:excluded) { Docile::FallbackContextProxy::NON_PROXIED_INSTANCE_VARIABLES }

    def create_fcp_and_set_one_instance_variable
      fcp = Docile::FallbackContextProxy.new(nil, nil)
      fcp.instance_variable_set(:@foo, 'foo')
      fcp
    end

    def type_of_ivar_names_on_this_ruby
      @a = 1
      instance_variables.first.class
    end

    it 'returns proxied instance variables' do
      subject.map(&:to_sym).should include(:@foo)
    end

    it "doesn't return non-proxied instance variables" do
      subject.map(&:to_sym).should_not include(*excluded)
    end

    it 'preserves the type (String or Symbol) of names on this ruby version' do
      actual_type_of_names.should == expected_type_of_names
    end
  end

end
