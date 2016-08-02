module Rtype
	module MethodAnnotator
		def self.included(base)
			base.extend ClassMethods
		end

		module ClassMethods
			def method_added(name)
				if @_rtype_component
					compo = @_rtype_component
					
					if compo.annotation_mode && !compo.ignoring
						if compo.has_undef?(name, false)
							compo.remove_undef(name, false)
						end
						
						compo.ignoring = true
						::Rtype::define_typed_method(self, name, compo.annotation_type_sig, false)
						compo.annotation_mode = false
						compo.annotation_type_sig = nil
						compo.ignoring = false
						
					elsif compo.has_undef?(name, false)
						info = compo.get_undef(name, false)
						compo.remove_undef(name, false)
						::Rtype.send(:redefine_method_to_typed, self, name, info[:expected], info[:result], false)
					end
				end
			end

			def singleton_method_added(name)
				if @_rtype_component
					compo = @_rtype_component
					
					if compo.annotation_mode && !compo.ignoring
						if compo.has_undef?(name, true)
							compo.remove_undef(name, true)
						end
						
						compo.ignoring = true
						::Rtype::define_typed_method(self, name, compo.annotation_type_sig, true)
						compo.annotation_mode = false
						compo.annotation_type_sig = nil
						compo.ignoring = false
						
					elsif compo.has_undef?(name, true)
						info = compo.get_undef(name, true)
						compo.remove_undef(name, true)
						::Rtype.send(:redefine_method_to_typed, self, name, info[:expected], info[:result], true)
					end
				end
			end
		end
	end
end
