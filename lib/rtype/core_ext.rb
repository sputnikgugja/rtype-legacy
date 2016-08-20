# true or false
module Boolean; end
class TrueClass; include Boolean; end
class FalseClass; include Boolean; end

Any = BasicObject

class Object
	include ::Rtype::MethodAnnotator
end

module Kernel
private
	def _rtype_component
		unless @_rtype_component
			@_rtype_component = ::Rtype::RtypeComponent.new
		end
		@_rtype_component
	end

	# Makes the method typed
	# 
	# With 'annotation mode', this method works for both instance method and singleton method (class method).
	# Without it (specifying method name), this method only works for instance method.
	# 
	# @param [#to_sym, nil] method_name The name of method. If nil, annotation mode works
	# @param [Hash] type_sig_info A type signature. e.g. [Integer] => Any
	# @return [void]
	# 
	# @note Annotation mode doesn't work in the outside of module
	# @raise [RuntimeError] If called outside of module
	# @raise [TypeSignatureError] If type_sig_info is invalid
	def rtype(method_name=nil, type_sig_info)
		if is_a?(Module)
			if method_name.nil?
				::Rtype::assert_valid_type_sig(type_sig_info)
				_rtype_component.annotation_mode = true
				_rtype_component.annotation_type_sig = type_sig_info
				nil
			else
				::Rtype::define_typed_method(self, method_name, type_sig_info, false)
			end
		else
			raise "rtype doesn't work in the outside of module"
		end
	end

	# Makes the singleton method (class method) typed
	# 
	# @param [#to_sym] method_name
	# @param [Hash] type_sig_info A type signature. e.g. [Integer] => Any
	# @return [void]
	# 
	# @raise [ArgumentError] If method_name is nil
	# @raise [TypeSignatureError] If type_sig_info is invalid
	def rtype_self(method_name, type_sig_info)
		::Rtype.define_typed_method(self, method_name, type_sig_info, true)
	end
	
	# Makes the accessor methods (getter and setter) typed
	# 
	# @param [Array<#to_sym>] names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @raise [RuntimeError] If called outside of module
	# @see #rtype
	def rtype_accessor(*names, type_behavior)
		rtype_reader(*names, type_behavior)
		rtype_writer(*names, type_behavior)
	end
	
	# Makes the accessor methods (getter and setter) typed
	# 
	# @param [Array<#to_sym>] names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @see #rtype_self
	def rtype_accessor_self(*names, type_behavior)
		rtype_reader_self(*names, type_behavior)
		rtype_writer_self(*names, type_behavior)
	end
	
	# Makes the getter methods typed
	# 
	# @param [Array<#to_sym>] names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @raise [RuntimeError] If called outside of module
	# @see #rtype
	def rtype_reader(*names, type_behavior)
		names.each do |name|
			raise ArgumentError, "names contains nil" if name.nil?
			
			name = name.to_sym
			if !respond_to?(name)
				attr_reader name
			end

			if is_a?(Module)
				::Rtype::define_typed_reader(self, name, type_behavior, false)
			else
				raise "rtype_reader doesn't work in the outside of module"
			end
		end
		nil
	end
	
	# Makes the getter methods typed
	# 
	# @param [Array<#to_sym>] names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @see #rtype_self
	def rtype_reader_self(*names, type_behavior)
		names.each do |name|
			raise ArgumentError, "names contains nil" if name.nil?
			
			name = name.to_sym
			if !respond_to?(name)
				singleton_class.send(:attr_reader, name)
			end
			::Rtype::define_typed_reader(self, name, type_behavior, true)
		end
		nil
	end
	
	# Makes the setter methods typed
	# 
	# @param [Array<#to_sym>] names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @raise [RuntimeError] If called outside of module
	# @see #rtype
	def rtype_writer(*names, type_behavior)
		names.each do |name|
			raise ArgumentError, "names contains nil" if name.nil?
			
			name = name.to_sym
			if !respond_to?(:"#{name}=")
				attr_writer name
			end

			if is_a?(Module)
				::Rtype::define_typed_writer(self, name, type_behavior, false)
			else
				raise "rtype_writer doesn't work in the outside of module"
			end
		end
		nil
	end
	
	# Makes the setter methods typed
	# 
	# @param [Array<#to_sym>] names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @see #rtype_self
	def rtype_writer_self(*names, type_behavior)
		names.each do |name|
			raise ArgumentError, "names contains nil" if name.nil?
			
			name = name.to_sym
			if !respond_to?(:"#{name}=")
				singleton_class.send(:attr_writer, name)
			end
			::Rtype::define_typed_writer(self, name, type_behavior, true)
		end
		nil
	end
	
	# Creates getter, setter methods.
	# The getter method is typed with Float
	# and the setter method is typed with Numeric.
	# 
	# If the setter is called with a numeric given,
	# the setter convert the numeric to a float, and store it.
	# 
	# As a result, setter can accept a Numeric(Integer/Float), and getter always returns a Float
	# 
	# @param [Array<#to_sym>] names
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	def float_accessor(*names)
		names.each do |name|
			raise ArgumentError, "names contains nil" if name.nil?
			
			name = name.to_sym
			rtype_reader name, Float
			define_method(:"#{name}=") do |val|
				instance_variable_set(:"@#{name}", val.to_f)
			end
			::Rtype::define_typed_writer(self, name, Numeric)
		end
		nil
	end
	
	# Creates getter, setter methods. And makes it typed with Boolean.
	# The name of the getter ends with `?`.
	# 
	# e.g. `bool_accessor :closed` will create `closed=` and `closed?` methods
	# 
	# @param [Array<#to_sym>] names
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	def bool_accessor(*names)
		names.each do |name|
			raise ArgumentError, "names contains nil" if name.nil?
			
			name = name.to_sym
			rtype_writer name, Boolean
			define_method(:"#{name}?") do |val|
				instance_variable_get(:"@#{name}")
			end
			::Rtype::define_typed_reader(self, :"#{name}?", Boolean)
		end
		nil
	end
end

class Method
	# @return [Boolean] Whether the method is typed with rtype
	def typed?
		!!::Rtype.type_signatures[owner][name]
	end

	# @return [TypeSignature]
	def type_signature
		::Rtype.type_signatures[owner][name]
	end

	# @return [Hash]
	# @see TypeSignature#info
	def type_info
		::Rtype.type_signatures[owner][name].info
	end
	
	# @return [Array, Hash]
	def argument_type
		::Rtype.type_signatures[owner][name].argument_type
	end

	# @return A type behavior
	def return_type
		::Rtype.type_signatures[owner][name].return_type
	end
end
