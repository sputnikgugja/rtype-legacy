require 'benchmark/ips'

require "rtype/legacy"
require "contracts"
require "contracts/version"

puts "Ruby version: #{RUBY_VERSION}"
puts "Ruby engine: #{RUBY_ENGINE}"
puts "Ruby description: #{RUBY_DESCRIPTION}"

puts "Rtype Legacy version: #{Rtype::Legacy::VERSION}"
puts "Contracts version: #{Contracts::VERSION}"

if !Rtype::Legacy::NATIVE_EXT_VERSION.nil?
	puts "Rtype Legacy with native extension"
elsif !Rtype::Legacy::JAVA_EXT_VERSION.nil?
	puts "Rtype Legacy with java extension"
else
	puts "Rtype Legacy without native extension"
end

class PureTest
	def sum(x, y)
		x + y
	end

	def mul(x, y)
		x * y
	end

	def args(a, b, c, d)
	end
end
pure_obj = PureTest.new

class RtypeTest
	rtype [Numeric, Numeric] => Numeric
	def sum(x, y)
		x + y
	end

	rtype [:to_i, :to_i] => Numeric
	def mul(x, y)
		x * y
	end

	rtype [Integer, Numeric, String, :to_i] => Any
	def args(a, b, c, d)
	end
end
rtype_obj = RtypeTest.new

class ContractsTest
	include Contracts

	Contract Num, Num => Num
	def sum(x, y)
		x + y
	end

	Contract RespondTo[:to_i], RespondTo[:to_i] => Num
	def mul(x, y)
		x * y
	end

	Contract Int, Num, String, RespondTo[:to_i] => Any
	def args(a, b, c, d)
	end
end
contracts_obj = ContractsTest.new

Benchmark.ips do |x|
	x.report("pure") do |times|
		i = 0
		while i < times
			pure_obj.sum(1, 2)
			pure_obj.mul(1, 2)
			pure_obj.args(1, 2, "c", 4)
			i += 1
		end
	end

	x.report("rtype-legacy") do |times|
		i = 0
		while i < times
			rtype_obj.sum(1, 2)
			rtype_obj.mul(1, 2)
			rtype_obj.args(1, 2, "c", 4)
			i += 1
		end
	end

	x.report("contracts") do |times|
		i = 0
		while i < times
			contracts_obj.sum(1, 2)
			contracts_obj.mul(1, 2)
			contracts_obj.args(1, 2, "c", 4)
			i += 1
		end
	end

	x.compare!
end
