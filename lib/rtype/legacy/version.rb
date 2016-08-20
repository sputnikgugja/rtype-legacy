module Rtype
	module Legacy
		VERSION = "0.0.4".freeze
		# rtype java extension version. nil If the extension is not used
		JAVA_EXT_VERSION = nil unless const_defined?(:JAVA_EXT_VERSION, false)
		# rtype c extension version. nil If the extension is not used
		NATIVE_EXT_VERSION = nil unless const_defined?(:NATIVE_EXT_VERSION, false)
	end
end
