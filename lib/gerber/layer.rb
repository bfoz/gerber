require 'gerber'
require 'units'

=begin
A Gerber information layer (not to be confused with a PCB layer)
=end
class Gerber
    class Layer
	attr_accessor :geometry, :name, :polarity, :step, :repeat

	def initialize(*args)
	    super

	    self.geometry = []
	    @polarity = :dark
	    @repeat = Vector[1,1]
	    @step = Vector[0,0]
	    @units = nil
	end

	# @group Accessors
	def empty?
	    self.geometry.empty?
	end

	def set_inches
	    @units = 'inch'
	end

	def set_millimeters
	    @units = 'millimeters'
	end
	# @endgroup
    end
end
