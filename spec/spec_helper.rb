require 'coveralls'
Coveralls.wear!

require 'rtype/legacy'
require 'rspec'
require 'set'

if !Rtype::Legacy::NATIVE_EXT_VERSION.nil?
	puts "Rtype Legacy with native extension"
elsif !Rtype::Legacy::JAVA_EXT_VERSION.nil?
	puts "Rtype Legacy with java extension"
else
	puts "Rtype Legacy without native extension"
end
