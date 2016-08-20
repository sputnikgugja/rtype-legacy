# Rtype Legacy: ruby with type (rtype for ruby 1.9+)
[![Gem Version](https://badge.fury.io/rb/rtype-legacy.svg)](https://badge.fury.io/rb/rtype-legacy)
[![Build Status](https://travis-ci.org/sputnikgugja/rtype-legacy.svg?branch=master)](https://travis-ci.org/sputnikgugja/rtype-legacy)
[![Coverage Status](https://coveralls.io/repos/github/sputnikgugja/rtype-legacy/badge.svg?branch=master)](https://coveralls.io/github/sputnikgugja/rtype-legacy?branch=master)

```ruby
require 'rtype/legacy'

class Test
  rtype [:to_i, Numeric] => Numeric
  def sum(a, b)
    a.to_i + b
  end

  # Second hash is keyword argument signature
  # (syntax compatibility with 'rtype' gem)
  rtype [{state: Boolean}, {}] => Boolean
  def self.invert(opts)
    !opts[:state]
  end
end

Test.new.sum(123, "asd")
# (Rtype::ArgumentTypeError) for 2nd argument:
# Expected "asd" to be a Numeric

Test.invert(state: 0)
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {:state=>0} to be a hash with 1 elements:
# - state : Expected 0 to be a Boolean
```

## Requirements
- Ruby >= 1.9
  - If you are using ruby 2.1+, see [rtype](https://github.com/sputnikgugja/rtype)
- MRI
  - If C native extension is used. otherwise it is not required
- JRuby (JRuby 1.7+)
  - If Java extension is used. otherwise it is not required

## Difference between rtype and rtype-legacy
- The two are separate gem
- Rtype requires ruby 2.1+. Rtype Legacy requires ruby 1.9+
- Rtype supports 'type checking for keyword argument'. Rtype Legacy doesn't
- Rtype uses `Module#prepend`. Rtype Legacy redefines method
- Rtype can be used outside of module (with specifying method name). Rtype Legacy can't be used outside of module

## Features
- Provides type checking for arguments and return
- [Type checking for hash elements](#hash)
- [Duck Typing](#duck-typing)
- [Typed Array](#typed-array), Typed Set, Typed Hash
- [Numeric check](#special-behaviors). e.g. `Int >= 0`
- [Type checking for getter and setter](#attr_accessor-with-rtype)
- [float_accessor](#float_accessor), [bool_accessor](#bool_accessor)
- Custom type behavior
- ...

## Installation
Run `gem install rtype-legacy` or add `gem 'rtype-legacy'` to your `Gemfile`

And add to your `.rb` source file:
```ruby
require 'rtype/legacy'
```

### Native extension
Rtype itself is pure-ruby gem. but you can make it more faster by using native extension.

#### Native extension for MRI
Run
```ruby
gem install rtype-legacy-native
```
or add to your `Gemfile`:
```ruby
gem 'rtype-legacy-native'
```
then, Rtype Legacy uses it. (**Do not** `require 'rtype-legacy-native'`)

#### Java extension for JRuby is automatic
**Do not** `require 'rtype-java'`

## Usage

### Supported Type Behaviors
- `Module` : Value must be of this module (`is_a?`)
  - `Any` : Alias for `BasicObject` (means Any Object)
  - `Boolean` : `true` or `false`
- `Symbol` : Value must respond to a method with this name
- `Regexp` : Value must match this regexp pattern
- `Range` : Value must be included in this range
- `Array` : Value can be any type in this array
- `Proc` : Value must return a truthy value for this proc
- `true` : Value must be truthy
- `false` : Value must be falsy
- `nil` : Value must be nil
- `Hash`
  - Value must be a hash
  - Each of elements must be valid
  - Keys of the value must be equal to keys of this hash
  - **String** key is **different** from **symbol** key
  - vs. Keyword arguments (e.g.)
    - `[{}]` is **not** hash argument. it is keyword argument, because its position is last
    - `[{}, {}]` is hash argument (first) and keyword argument (second)
    - `[{}, {}, {}]` is two hash argument (first, second) and keyword argument (last)
    - `{}` is keyword argument. non-keyword arguments must be in array.
  - Of course, nested hash works
  - Example: [Hash](#hash)
  
- [Special Behaviors](#special-behaviors)
  - `TypedArray, TypedSet, TypedHash`, `Num, Int, Flo`, `And`, `Xor`, `Not`, `Nilable`

### Examples

#### Basic
```ruby
require 'rtype'

class Example
  rtype [Integer] => nil
  def test(i)
  end
  
  rtype [Any] => nil
  def any_type_arg(arg)
  end
  
  rtype [] => Integer
  def return_type_test
    "not integer"
  end
end

e = Example.new
e.test("not integer")
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected "not integer" to be a Integer

e.any_type_arg("Any argument!") # Works

e.return_type_test
# (Rtype::ReturnTypeError) for return:
# Expected "not integer" to be a Integer
```

#### Duck typing
```ruby
require 'rtype'

class Duck
  rtype [:to_i] => Any
  def says(i)
    puts "duck:" + " quack"*i.to_i
  end
end

Duck.new.says("2") # duck: quack quack
```

#### Array
```ruby
rtype :ruby!, [[String, Integer]] => Any
def ruby!(arg)
	puts "ruby!"
end

func("str") # ruby!
func(123) # ruby!

func(nil)
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected nil to be a String
# OR Expected nil to be a Integer
```

#### Hash
```ruby
# last hash element is keyword arguments
rtype :func, [{msg: String}, {}] => Any
def func(hash)
  puts hash[:msg]
end

func({})
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {} to be a hash with 1 elements:
# - msg : Expected nil to be a String

func({msg: 123})
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {:msg=>123} to be a hash with 1 elements:
# - msg : Expected 123 to be a String

func({msg: "hello", key: 'value'})
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {:msg=>"hello", :key=>"value"} to be a hash with 1 elements:
# - msg : Expected "hello" to be a String

func({"msg" => "hello hash"})
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {"msg"=>"hello hash"} to be a hash with 1 elements:
# - msg : Expected nil to be a String

func({msg: "hello hash"}) # hello hash
```

#### attr_accessor with rtype
- `rtype_accessor(*names, type)` : calls `attr_accessor` if the accessor methods(getter/setter) are not defined. and makes it typed
- `rtype_reader(*names, type)` : calls `attr_reader` if the getters are not defined. and makes it typed
- `rtype_writer(*names, type)` : calls `attr_writer` if the setters are not defined. and makes it typed

You can use `rtype_accessor_self` for static accessor. (`rtype_reader_self`, `rtype_writer_self` also exist)

```ruby
require 'rtype'

class Example
  rtype_accessor :value, String

  def initialize
    @value = 456
  end
end

Example.new.value = 123
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected 123 to be a String

Example.new.value
# (Rtype::ReturnTypeError) for return:
# Expected 456 to be a String
```

#### Typed Array
```ruby
### TEST 1 ###
class Test
	rtype [Array.of(Integer)] => Any
	def sum(args)
		num = 0
		args.each { |e| num += e }
	end
end

sum([1, 2, 3]) # => 6

sum([1.0, 2, 3])
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected [1.0, 2, 3] to be an array with type Integer"
```

```ruby
### TEST 2 ###
class Test
	rtype [ Array.of([Integer, Float]) ] => Any
	def sum(args)
		num = 0
		args.each { |e| num += e }
	end
end

sum([1, 2, 3]) # => 6
sum([1.0, 2, 3]) # => 6.0
```

#### float_accessor
```ruby
class Point
  float_accessor :x, :y
end

v = Point.new
v.x = 1
v.x # => 1.0 (always Float)
```

#### bool_accessor
```ruby
class Human
  bool_accessor :hungry
end

a = Human.new
a.hungry = true
a.hungry? # => true
a.hungry # NoMethodError
```

#### `rtype`
```ruby
require 'rtype'

class Example
  # Recommended. With annotation mode (no method name required)
  rtype [Integer, String] => String
  def hello_world(i, str)
    puts "Hello? #{i} #{st
  end

  # Works (with specifying method name)
  rtype :hello_world, [Integer, String] => String
  def hello_world(i, str)
    puts "Hello? #{i} #{st
  end
  
  # Works
  def hello_world_two(i, str)
    puts "Hello? #{i} #{str}"
  end
  rtype :hello_world_two, [Integer, String] => String
  
  # Also works (String will be converted to Symbol)
  rtype 'hello_world_three', [Integer, String] => String
  def hello_world_three(i, str)
    puts "Hello? #{i} #{str}"
  end

  # Doesn't work. annotation mode works for following (next) method
  def hello_world_four(i, str)
    puts "Hello? #{i} #{str}"
  end
  rtype [Integer, String] => String
end
```

#### Class method
Annotation mode works for both instance method and class method

```ruby
require 'rtype'

class Example
  rtype [:to_i] => Any
  def self.say_ya(i)
    puts "say" + " ya"*i.to_i
  end
end

Example::say_ya(3) #say ya ya ya
```

if you specify method name, however, you must use `rtype_self` instead of `rtype`

```ruby
require 'rtype'

class Example
  rtype_self :say_ya, [:to_i] => Any
  def self.say_ya(i)
    puts "say" + " ya"*i.to_i
  end
end

Example::say_ya(3) #say ya ya ya
```

#### Type information
This is just 'information'

Any change of this doesn't affect type checking

```ruby
require 'rtype'

class Example
  rtype [:to_i] => Any
  def test(i)
  end
end

Example.new.method(:test).type_info
# => [:to_i] => Any
Example.new.method(:test).argument_type
# => [:to_i]
Example.new.method(:test).return_type
# => Any
```

#### Special Behaviors
  - `TypedArray` : Ensures value is an array with the type (type signature)
    - `Array.of(type)` (recommended)
    - Example: [TypedArray](#typed-array)
    
  - `TypedSet` : Ensures value is a set with the type (type signature)
    - `Set.of(type)` (recommended)
    
  - `TypedHash` : Ensures value is a hash with the type (type signature)
    - `Hash.of(key_type, value_type)` (recommended)
  
  - `Num, Int, Flo` : Numeric check
    - `Num/Int/Flo >/>=/</<=/== x`
    - e.g. `Num >= 2` means value must be a `Numeric` and >= 2
    - e.g. `Int >= 2` means value must be a `Integer` and >= 2
    - e.g. `Flo >= 2` means value must be a `Float` and >= 2
  
  - `And` : Ensures value is valid for all given types
    - `Rtype.and(*types)`, `Rtype::Behavior::And[*types]`
    - or `Array#comb`, `Object#and(*others)`
    
  - `Xor` : Ensures value is valid for only one of given types
    - `Rtype.xor(*types)`, `Rtype::Behavior::Xor[*types]`
    - or `Object#xor(*others)`

  - `Not` : Ensures value is not valid for all given types
    - `Rtype.not(*types)`, `Rtype::Behavior::Not[*types]`
    - or `Object#not`

  - `Nilable` : Value can be nil
    - `Rtype.nilable(type)`, `Rtype::Behavior::Nilable[type]`
    - or `Object#nilable`, `Object#or_nil`

  - You can create custom behaviors by extending `Rtype::Behavior::Base`

## Documentation
[RubyDoc.info](http://www.rubydoc.info/gems/rtype-legacy)

## Benchmarks
Result of `rake benchmark` ([source](https://github.com/sputnikgugja/rtype-legacy/tree/master/benchmark/benchmark.rb))

Rubype and Sig don't support 1.9 ruby. Typecheck raises an error in my environment

### MRI
```
Ruby version: 1.9.3
Ruby engine: ruby
Ruby description: ruby 1.9.3p551 (2014-11-13 revision 48407) [i686-linux]
Rtype Legacy version: 0.0.1
Contracts version: 0.14.0
Rtype Legacy with native extension
Warming up --------------------------------------
                pure    49.620k i/100ms
        rtype-legacy    13.038k i/100ms
           contracts     2.765k i/100ms
Calculating -------------------------------------
                pure      2.037M (± 1.9%) i/s -     10.222M
        rtype-legacy    179.155k (± 2.3%) i/s -    899.622k
           contracts     30.576k (± 0.9%) i/s -    154.840k

Comparison:
                pure:  2036909.8 i/s
        rtype-legacy:   179155.3 i/s - 11.37x slower
           contracts:    30575.8 i/s - 66.62x slower
```

### JRuby
```
Ruby version: 1.9.3
Ruby engine: jruby
Ruby description: jruby 1.7.23 (1.9.3p551) 2015-11-24 f496dd5 on Java HotSpot(TM) Server VM 1.8.0_91-b14 +jit [linux-i386]
Rtype Legacy version: 0.0.1
Contracts version: 0.14.0
Rtype Legacy with java extension
Warming up --------------------------------------
                pure    76.140k i/100ms
        rtype-legacy     5.123k i/100ms
           contracts     1.422k i/100ms
Calculating -------------------------------------
                pure      6.330M (± 9.7%) i/s -     30.913M
        rtype-legacy    293.793k (± 4.4%) i/s -      1.465M
           contracts     33.924k (± 2.3%) i/s -    170.640k

Comparison:
                pure:  6329735.2 i/s
        rtype-legacy:   293793.2 i/s - 21.54x slower
           contracts:    33924.0 i/s - 186.59x slower
```

## Author
Sputnik Gugja (sputnikgugja@gmail.com)

## License
MIT license (@ Sputnik Gugja)

See `LICENSE` file.
