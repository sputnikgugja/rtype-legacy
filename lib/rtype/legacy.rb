if Object.const_defined?(:RUBY_ENGINE)
	case RUBY_ENGINE
	when "jruby"
		begin
			require 'java'
			require 'rtype/legacy/rtype_legacy_java'
			# puts "Rtype Legacy with Java extension"
		rescue LoadError
			# puts "Rtype Legacy without native extension"
		end
	when "ruby"
		begin
			require 'rtype/legacy/rtype_legacy_native'
			# puts "Rtype Legacy with C native extension"
		rescue LoadError
			# puts "Rtype Legacy without native extension"
		end
	end
end

require_relative 'rtype_component'
require_relative 'method_annotator'
require_relative 'core_ext'
require_relative 'legacy/version'
require_relative 'type_signature_error'
require_relative 'argument_type_error'
require_relative 'return_type_error'
require_relative 'type_signature'
require_relative 'behavior'

module Rtype
	extend self
	
	# This is just 'information'
	# Any change of this doesn't affect type checking
	@@type_signatures = Hash.new

	# Makes the method typed
	# @param owner Owner of the method
	# @param [#to_sym] method_name
	# @param [Hash] type_sig_info A type signature. e.g. `[Integer, Float] => Float`
	# @param [Boolean] singleton Whether the method is singleton method
	# @return [void]
	# 
	# @raise [ArgumentError] If method_name is nil, keyword argument signature is not empty, or singleton is not a boolean
	# @raise [TypeSignatureError] If type_sig_info is invalid
	def define_typed_method(owner, method_name, type_sig_info, singleton)
		method_name = method_name.to_sym
		raise ArgumentError, "method_name is nil" if method_name.nil?
		raise ArgumentError, "singleton must be a boolean" unless singleton.is_a?(Boolean)
		assert_valid_type_sig(type_sig_info)

		el = type_sig_info.first
		arg_sig = el[0]
		return_sig = el[1]

		if arg_sig.is_a?(Array)
			expected_args = arg_sig.dup
			if expected_args.last.is_a?(Hash)
				kwargs = expected_args.pop
				# empty kwargs signature
			else
				# empty kwargs signature
			end
		elsif arg_sig.is_a?(Hash)
			# empty kwargs signature
			expected_args = []
		end

		sig = TypeSignature.new
		sig.argument_type = arg_sig
		sig.return_type = return_sig
		unless @@type_signatures.key?(owner)
			@@type_signatures[owner] = {}
		end
		@@type_signatures[owner][method_name] = sig

		redefine_method_to_typed(owner, method_name, expected_args, return_sig, singleton)
	end
	
	# @param owner Owner of the accessor
	# @param [#to_sym] name
	# @param type_behavior A type behavior. e.g. Integer
	# @param [Boolean] singleton Whether the method is singleton method
	# @return [void]
	# 
	# @raise [ArgumentError] If name is nil
	# @raise [TypeSignatureError]
	def define_typed_accessor(owner, name, type_behavior, singleton)
		define_typed_reader(owner, name, type_behavior, singleton)
		define_typed_writer(owner, name, type_behavior, singleton)
	end
	
	# @param owner Owner of the getter
	# @param [#to_sym] name
	# @param type_behavior A type behavior. e.g. Integer
	# @param [Boolean] singleton Whether the method is singleton method
	# @return [void]
	# 
	# @raise [ArgumentError] If name is nil
	# @raise [TypeSignatureError]
	def define_typed_reader(owner, name, type_behavior, singleton)
		raise ArgumentError, "name is nil" if name.nil?
		valid?(type_behavior, nil)
		define_typed_method owner, name.to_sym, {[] => type_behavior}, singleton
	end
	
	# @param owner Owner of the setter
	# @param [#to_sym] name
	# @param type_behavior A type behavior. e.g. Integer
	# @param [Boolean] singleton Whether the method is singleton method
	# @return [void]
	# 
	# @raise [ArgumentError] If name is nil
	# @raise [TypeSignatureError]
	def define_typed_writer(owner, name, type_behavior, singleton)
		raise ArgumentError, "name is nil" if name.nil?
		valid?(type_behavior, nil)
		define_typed_method owner, :"#{name.to_sym}=", {[type_behavior] => Any}, singleton
	end

	# This is just 'information'
	# Any change of this doesn't affect type checking
	# 
	# @return [Hash]
	# @note type_signatures[owner][method_name]
	def type_signatures
		@@type_signatures
	end
	
	# @param [Integer] idx
	# @param expected A type behavior
	# @param value
	# @return [String] A error message
	# 
	# @raise [ArgumentError] If expected is invalid
	def arg_type_error_message(idx, expected, value)
		"#{arg_message(idx)}\n" + type_error_message(expected, value)
	end

	# @return [String]
	def arg_message(idx)
		"for #{ordinalize_number(idx+1)} argument:"
	end

	# Returns a error message for the pair of type behavior and value
	# 
	# @param expected A type behavior
	# @param value
	# @return [String] error message
	# 
	# @note This method doesn't check the value is valid
	# @raise [TypeSignatureError] If expected is invalid
	def type_error_message(expected, value)
		case expected
		when Rtype::Behavior::Base
			expected.error_message(value)
		when Module
			"Expected #{value.inspect} to be a #{expected}"
		when Symbol
			"Expected #{value.inspect} to respond to :#{expected}"
		when Regexp
			"Expected stringified #{value.inspect} to match regexp #{expected.inspect}"
		when Range
			"Expected #{value.inspect} to be included in range #{expected.inspect}"
		when Array
			arr = expected.map { |e| type_error_message(e, value) }
			arr.join("\nOR ")
		when Hash
			if value.is_a?(Hash)
				arr = []
				expected.each do |k, v|
					if v.is_a?(Array) || v.is_a?(Hash)
						arr << "- #{k} : {\n" + type_error_message(v, value[k]) + "\n}"
					else
						arr << "- #{k} : " + type_error_message(v, value[k])
					end
				end
				"Expected #{value.inspect} to be a hash with #{expected.length} elements:\n" + arr.join("\n")
			else
				"Expected #{value.inspect} to be a hash"
			end
		when Proc
			"Expected #{value.inspect} to return a truthy value for proc #{expected}"
		when true
			"Expected #{value.inspect} to be a truthy value"
		when false
			"Expected #{value.inspect} to be a falsy value"
		when nil # for return
			"Expected #{value.inspect} to be nil"
		else
			raise TypeSignatureError, "Invalid type behavior #{expected}"
		end
	end

	# Checks the type signature is valid
	# 
	# e.g.
	# `[Integer] => Any` is valid.
	# `[Integer]` or `Any` are invalid
	# 
	# @param sig A type signature
	# @raise [TypeSignatureError] If sig is invalid
	def assert_valid_type_sig(sig)
		unless sig.is_a?(Hash)
			raise TypeSignatureError, "Invalid type signature: type signature is not hash"
		end
		if sig.empty?
			raise TypeSignatureError, "Invalid type signature: type signature is empty hash"
		end
		assert_valid_arguments_type_sig(sig.first[0])
		assert_valid_return_type_sig(sig.first[1])
	end

	# Checks the arguments type signature is valid
	# 
	# e.g.
	# `[Integer]`, `{key: "value"}` are valid (the second is keyword argument signature and ignored in rtype-legacy).
	# `Integer` is invalid.
	# 
	# @param sig A arguments type signature
	# @raise [TypeSignatureError] If sig is invalid
	def assert_valid_arguments_type_sig(sig)
		if sig.is_a?(Array)
			sig = sig.dup
			if sig.last.is_a?(Hash)
				kwargs = sig.pop
			else
				kwargs = {}
			end
			sig.each { |e| assert_valid_argument_type_sig_element(e) }
			unless kwargs.empty?
				raise TypeSignatureError, "Invalid type signature: keyword arguments must be empty"
			end
		elsif sig.is_a?(Hash)
			unless kwargs.empty?
				raise TypeSignatureError, "Invalid type signature: keyword arguments must be empty"
			end
		else
			raise TypeSignatureError, "Invalid type signature: arguments type signature is neither array nor hash"
		end
	end

	# Checks the type behavior is valid
	# 
	# @param sig A type behavior
	# @raise [TypeSignatureError] If sig is invalid
	def assert_valid_argument_type_sig_element(sig)
		case sig
		when Rtype::Behavior::Base
		when Module
		when Symbol
		when Regexp
		when Range
		when Array
			sig.each do |e|
				assert_valid_argument_type_sig_element(e)
			end
		when Hash
			sig.each_value do |e|
				assert_valid_argument_type_sig_element(e)
			end
		when Proc
		when true
		when false
		when nil
		else
			raise TypeSignatureError, "Invalid type signature: Unknown type behavior #{sig}"
		end
	end

	# @see #assert_valid_argument_type_sig_element
	def assert_valid_return_type_sig(sig)
		assert_valid_argument_type_sig_element(sig)
	end
	
	unless respond_to?(:valid?)
	# Checks the value is valid for the type behavior
	# 
	# @param expected A type behavior
	# @param value
	# @return [Boolean]
	# 
	# @raise [TypeSignatureError] If expected is invalid
	def valid?(expected, value)
		case expected
		when Module
			value.is_a? expected
		when Symbol
			value.respond_to? expected
		when Regexp
			!!(expected =~ value.to_s)
		when Range
			expected.include?(value)
		when Hash
			return false unless value.is_a?(Hash)
			return false unless expected.keys == value.keys
			expected.all? { |k, v| valid?(v, value[k]) }
		when Array
			expected.any? { |e| valid?(e, value) }
		when Proc
			!!expected.call(value)
		when true
			!!value
		when false
			!value
		when Rtype::Behavior::Base
			expected.valid? value
		when nil
			value.nil?
		else
			raise TypeSignatureError, "Invalid type signature: Unknown type behavior #{expected}"
		end
	end
	end

	unless respond_to?(:assert_arguments_type)
	# Validates arguments
	# 
	# @param [Array] expected_args A type signature for non-keyword arguments
	# @param [Array] args
	# @return [void]
	# 
	# @raise [TypeSignatureError] If expected_args is invalid
	# @raise [ArgumentTypeError] If args is invalid
	def assert_arguments_type(expected_args, args)
		e_len = expected_args.length
		# `length.times` is faster than `each_with_index`
		args.length.times do |i|
			break if i >= e_len
			expected = expected_args[i]
			value = args[i]
			unless valid?(expected, value)
				raise ArgumentTypeError, "#{arg_message(i)}\n" + type_error_message(expected, value)
			end
		end
		nil
	end
	end

	# Validates result
	# 
	# @param expected A type behavior
	# @param result
	# @return [void]
	# 
	# @raise [TypeSignatureError] If expected is invalid
	# @raise [ReturnTypeError] If result is invalid
	unless respond_to?(:assert_return_type)
	def assert_return_type(expected, result)
		unless valid?(expected, result)
			raise ReturnTypeError, "for return:\n" + type_error_message(expected, result)
		end
		nil
	end
	end

private
	# @param owner
	# @param [Symbol] method_name
	# @param [Array] expected_args
	# @param return_sig
	# @param [Boolean] singleton
	# @return [void]
	def redefine_method_to_typed(owner, method_name, expected_args, return_sig, singleton)
		compo = owner.send(:_rtype_component)
		
		methods = owner.instance_methods if !singleton
		methods = owner.methods if singleton
		
		if methods.include?(method_name)
=begin
			unless compo.has_old?(method_name, singleton)
				old_method = owner.instance_method(method_name) if !singleton
				old_method = owner.method(method_name) if singleton
				compo.set_old(method_name, singleton, old_method)
			end
=end
			if compo.has_old?(method_name, singleton)
				old_method = compo.get_old(method_name, singleton)
			else
				old_method = owner.instance_method(method_name) if !singleton
				old_method = owner.method(method_name) if singleton
				compo.set_old(method_name, singleton, old_method)
			end
		else # Undefined method
			compo.add_undef(method_name, expected_args, return_sig, singleton)
			return
		end
		
		owner = owner.singleton_class if singleton
		priv = owner.private_method_defined?(method_name)
		prot = owner.protected_method_defined?(method_name)
		
		if !singleton
			# `send` is faster than `method(...).call`
			owner.send :define_method, method_name do |*args, &block|
				::Rtype::assert_arguments_type(expected_args, args)
				# result = compo.get_old(method_name, singleton).bind(self).call(*args, &block)
				result = old_method.bind(self).call(*args, &block)
				::Rtype::assert_return_type(return_sig, result)
				result
			end
		else
			owner.send :define_method, method_name do |*args, &block|
				::Rtype::assert_arguments_type(expected_args, args)
				# result = compo.get_old(method_name, singleton).call(*args, &block)
				result = old_method.call(*args, &block)
				::Rtype::assert_return_type(return_sig, result)
				result
			end
		end
		
		if priv
			owner.send(:private, method_name)
		elsif prot
			owner.send(:protected, method_name)
		end
		nil
	end
	
	# @param [Integer] num
	# @return [String]
	def ordinalize_number(num)
	    if (11..13).include?(num % 100)
			"#{num}th"
	    else
			case num % 10
			when 1; "#{num}st"
			when 2; "#{num}nd"
			when 3; "#{num}rd"
			else "#{num}th"
			end
	    end
	end
end
