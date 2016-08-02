module Rtype
	class RtypeComponent
		attr_accessor :annotation_mode, :annotation_type_sig, :ignoring
		attr_reader :undef_methods, :old_methods
		
		def initialize
			@annotation_mode = false
			@annotation_type_sig = nil
			@ignoring = false
			@undef_methods = {}
			@old_methods = {}
		end
		
		def set_old(name, singleton, method)
			@old_methods[singleton] ||= {}
			@old_methods[singleton][name] = method
		end
		
		def get_old(name, singleton)
			@old_methods[singleton][name]
		end
		
		def has_old?(name, singleton)
			@old_methods.key?(singleton) && @old_methods[singleton].key?(name)
		end
		
		# @param [Symbol] name
		# @param [Array] expected_args
		# @param return_sig
		# @param [Boolean] singleton
		def add_undef(name, expected_args, return_sig, singleton)
			obj = { expected: expected_args, result: return_sig }
			@undef_methods[singleton] ||= {}
			@undef_methods[singleton][name] = obj
		end
		
		def has_undef?(name, singleton)
			@undef_methods.key?(singleton) && @undef_methods[singleton].key?(name)
		end
		
		def remove_undef(name, singleton)
			@undef_methods[singleton].delete(name)
		end
		
		def get_undef(name, singleton)
			@undef_methods[singleton][name]
		end
	end
end
