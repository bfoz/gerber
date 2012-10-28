=begin
An Aperture definition for an Extended {Gerber} file
=end
class Gerber
    class Aperture
	attr_reader :diameter, :type, :x, :y
	attr_accessor :hole, :parameters, :rotation

	def initialize(parameters)
	    raise ArgumentError unless parameters.is_a? Hash
	    parameters.each {|k| self.instance_variable_set("@#{k.first}", k.last) }
	end

	def ==(other)
	    (self.diameter == other.diameter) && (self.hole == other.hole) && (self.parameters == other.parameters) && (self.rotation == other.rotation) && (self.type == other.type) && (self.x == other.x) && (self.y == other.y)
	end
    end
end
