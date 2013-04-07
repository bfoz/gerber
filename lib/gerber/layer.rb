require 'gerber'
require 'units'

=begin
A Gerber information layer (not to be confused with a PCB layer)
=end
class Gerber
    class Layer
	attr_accessor :apertures, :geometry, :name, :polarity, :step, :repeat

	def initialize
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

	# @return [Rectangle]   A {Geometry::Rectangle} that bounds the {Layer}
	def bounds
	    return nil if self.apertures.empty?

	    min_x, min_y, max_x, max_y = element_minmax(self.apertures.keys.first.size, self.apertures.values.first.first || self.geometry.first)
	    self.apertures.each do |aperture, geometry|
		size = aperture.size
		size = Size[size, size] if size.kind_of? Numeric

		geometry.each do |element|
		    minx, miny, maxx, maxy = element_minmax(size, element)
		    min_x, max_x = [min_x, max_x, minx, maxx].minmax
		    min_y, max_y = [min_y, max_y, miny, maxy].minmax
		end
	    end

	    Geometry::Rectangle.new min_x, min_y, max_x, max_y
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

private
	# @param [Size] aperture_size	The size of the {Aperture} used to draw the element
	# @return [min_x, min_y, max_x, max_y]
	def element_minmax(aperture_size, element)
	    half_size_x = aperture_size[0]/2.0
	    half_size_y = aperture_size[1]/2.0

	    case element
		when Geometry::Line
		    a = [[element.first.x, element.last.x].minmax, [element.first.y, element.last.y].minmax].flatten
		    a.zip([-half_size_x, -half_size_y, half_size_x, half_size_y]).map {|a,b| a + b }
	    end
	end
    end
end
