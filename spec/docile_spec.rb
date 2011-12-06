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
    end

    def outer(&block)
      Docile.dsl_eval(OuterDSL.new, &block)
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

      it "should write instance variable assigned in block into outer dsl scope" do
        @iv1 = 'foo'; outer { @iv1 = 'bar' }; @iv1.should == 'bar'
      end

      it "should find instance variable from block definition in inner dsl scope" do
        @iv2 = 'iv2'; outer { inner { @iv2.should == 'iv2' } }
      end

      it "should find instance variable from block definition in inner dsl scope" do
        @iv2 = 'foo'; outer { inner { @iv2 = 'bar' } }; @iv2.should == 'bar'
      end
    end

  end

end