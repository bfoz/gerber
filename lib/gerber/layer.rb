require 'gerber'
require 'units'

=begin
A Gerber information layer (not to be confused with a PCB layer)
=end
class Gerber
    class Layer
	attr_accessor :apertures, :geometry, :name, :polarity, :step, :repeat

	def initialize(*args)
	    super

	    self.apertures = {}
	    @polarity = :dark
	    @repeat = Vector[1,1]
	    @step = Vector[0,0]
	    @units = nil
	end

	# @group Accessors
	# @return [Bool]    True if polarity is set to :clear
	def clear?
	    :clear == @polarity
	end

	# @return [Bool]    True if polarity is set to :dark
	def dark?
	    :dark == @polarity
	end

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

	# @group Geometry
	def add_line(aperture, start_point, end_point)
	    if @apertures.has_key? aperture
		@apertures[aperture] << Geometry::Line[start_point, end_point]
	    else
		@apertures[aperture] = [Geometry::Line[start_point, end_point]]
	    end
	end
	# @endgroup
    end
end
