require 'gerber'
require 'units'

=begin
A Gerber information layer (not to be confused with a PCB layer)
=end
class Gerber
    class Layer < Struct.new(:draw, :eof, :geometry)
	attr_accessor :name, :polarity, :step, :repeat

	def initialize(*args)
	    super

	    self.geometry = []
	    @polarity = :dark
	    @repeat = Vector[1,1]
	    @step = Vector[0,0]
	    @units = nil
	end

	def <<(arg)
	    raise ParseError, "Must set an aperture before generating geometry" unless self.current_aperture
	    self.geometry[self.current_aperture] << arg if arg.kind_of?(Line) || arg.kind_of?(Point) || arg.kind_of?(Arc)
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

	def apply_units(a)
	    raise ParseError, "Units must be set before specifying coordinates" unless @units
	    return nil unless a
	    (@units == 'inch') ? a.inch : a.mm
	end
    end
end
