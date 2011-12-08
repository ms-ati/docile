# Docile

Definition: *Ready to accept control or instruction; submissive* [[1]]

Tired of overly complex DSL libraries and hairy meta-programming?

Let's make our Ruby DSLs more docile...

[1]: http://www.google.com/search?q=docile+definition   "Google"

## Usage

Let's treat an Array's methods as its own DSL:

``` ruby
Docile.dsl_eval([]) do
  push 1
  push 2
  pop
  push 3
end
#=> [1, 3]
```

Mutating (changing) the array is fine, but what you probably really want as your DSL is actually a [Builder Pattern][2].

For example, if you have a PizzaBuilder class that can already build a Pizza:

``` ruby
@sauce_level = :extra
pizza = PizzaBuilder.new.cheese.pepperoni.sauce(@sauce_level).build
#=> #<Pizza:0x00001009dc398 @cheese=true, @pepperoni=true, @bacon=false, @sauce=:extra>
```

Then you can use this same PizzaBuilder class as a DSL:

``` ruby
@sauce_level = :extra
pizza = Docile.dsl_eval(PizzaBuilder.new) do
  cheese
  pepperoni
  sauce @sauce_level
end.build
#=> #<Pizza:0x00001009dc398 @cheese=true, @pepperoni=true, @bacon=false, @sauce=:extra>
```

It's just that easy!

[2]: http://stackoverflow.com/questions/328496/when-would-you-use-the-builder-pattern  "Builder Pattern"

## Features

  1.  method lookup falls back from the DSL object to the block's context
  2.  local variable lookup falls back from the DSL object to the block's context
  3.  instance variables are from the block's context only
  4.  nested dsl evaluation

## Installation

``` bash
$ gem install docile
```

## Documentation

Documentation hosted on *rubydoc.info*: [Docile Documentation](http://rubydoc.info/gems/docile)
Or, read the code hosted on *github.com*: [Docile Code](https://github.com/ms-ati/docile)

## Note on Patches/Pull Requests

  * Fork the project.
  * Setup your development environment with: gem install bundler; bundle install
  * Make your feature addition or bug fix.
  * Add tests for it. This is important so I don't break it in a
    future version unintentionally.
  * Commit, do not mess with rakefile, version, or history.
    (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
  * Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2011 Marc Siegel. See LICENSE for details.
