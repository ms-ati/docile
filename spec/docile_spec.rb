require "spec_helper"

describe Docile do

  context :dsl_eval do

    it "should return the DSL object" do
      Docile.dsl_eval([]) do
        push 1
        push 2
        pop
        push 3
      end.should == [1, 3]
    end

    it "should use the __id__ method of the proxy object" do
      arr = []
      Docile.dsl_eval(arr) { __id__.should_not == arr.__id__ }
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

    it "should handle a Builder pattern" do
      @sauce = :extra
      Docile.dsl_eval(PizzaBuilder.new) do
        bacon
        cheese
        sauce @sauce
      end.build.should == Pizza.new(true, false, true, :extra)
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

    def parameterized(*args, &block)
      Docile.dsl_eval(OuterDSL.new, *args, &block)
    end

    context "parameters" do
      it "should pass parameters to the block" do
        parameterized(1,2,3) do |x,y,z|
          x.should == 1
          y.should == 2
          z.should == 3
        end
      end

      it "should find parameters before methods" do
        parameterized(1) { |a| a.should == 1 }
      end

      it "should find outer parameters in inner dsl scope" do
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

    context "methods" do
      it "should find method of outer dsl in outer dsl scope" do
        outer { a.should == 'a' }
      end

      it "should find method of inner dsl in inner dsl scope" do
        outer { inner { b.should == 'b' } }
      end

      it "should find method of outer dsl in inner dsl scope" do
        outer { inner { a.should == 'a' } }
      end

      it "should find method of block's context in outer dsl scope" do
        def c; 'c'; end
        outer { c.should == 'c' }
      end

      it "should find method of block's context in inner dsl scope" do
        def c; 'c'; end
        outer { inner { c.should == 'c' } }
      end

      it "should find method of outer dsl in preference to block context" do
        def a; 'not a'; end
        outer { a.should == 'a' }
        outer { inner { a.should == 'a' } }
      end
    end

    context "local variables" do
      it "should find local variable from block context in outer dsl scope" do
        foo = 'foo'
        outer { foo.should == 'foo' }
      end

      it "should find local variable from block definition in inner dsl scope" do
        bar = 'bar'
        outer { inner { bar.should == 'bar' } }
      end
    end

    context "instance variables" do
      it "should find instance variable from block definition in outer dsl scope" do
        @iv1 = 'iv1'; outer { @iv1.should == 'iv1' }
      end

      it "should proxy instance variable assignments in block in outer dsl scope back into block's context" do
        @iv1 = 'foo'; outer { @iv1 = 'bar' }; @iv1.should == 'bar'
      end

      it "should find instance variable from block definition in inner dsl scope" do
        @iv2 = 'iv2'; outer { inner { @iv2.should == 'iv2' } }
      end

      it "should proxy instance variable assignments in block in inner dsl scope back into block's context" do
        @iv2 = 'foo'; outer { inner { @iv2 = 'bar' } }; @iv2.should == 'bar'
      end
    end

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

    def respond path, &block
      MessageDispatch.instance.add_responder path, &block
    end

    def send_request path, request
      MessageDispatch.instance.dispatch path, request
    end

    it "should handle the dispatch pattern" do
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
