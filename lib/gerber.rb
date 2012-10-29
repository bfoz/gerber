require 'geometry'
require 'units'
require_relative 'gerber/layer/parser'

=begin
Read and write {http://en.wikipedia.org/wiki/Gerber_Format Gerber} files (RS-274X)
=end
class Gerber
    ParseError = Class.new(StandardError)

    Arc = Geometry::Arc
    Line = Geometry::Line
    Point = Geometry::Point

    attr_accessor :integer_places, :decimal_places
    attr_accessor :zero_omission

    attr_reader :apertures, :layers

    def initialize
	@apertures = []
	@layers = []
	@polarity = :positive
	@units = nil
    end

    # Set the format used for coordinates
    # @param [Number] integer_places	The number of digits to the left of the decimal point
    # @param [Number] decimal_places	The number of digits to the right of the decimal point
    def coordinate_format=(*args)
	self.integer_places, self.decimal_places = args.flatten.map {|a| a.to_i }
    end

    # Read and parse the given file into a {Gerber} object
    # @return [Gerber]	The resulting {Gerber} object, or nil on failure
    def self.read(filename)
	File.open(filename) do |f|
	    Gerber::Parser.new.parse(f)
	end
    end

    def self.write(filename, container)
    end
end
