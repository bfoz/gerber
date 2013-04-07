require 'minitest/autorun'
require 'gerber/exceptions'
require 'gerber'
require 'stringio'

describe Gerber do
    it "must read a file" do
	Gerber.read('test/gerber/hexapod.gerber').must_be_kind_of(Gerber)
    end

    it "must read the 4PCB.com example" do
	Gerber.read('test/fixtures/sample_4pcb.gerber')
    end

    it "must read the Wikipedia example" do
	Gerber.read('test/fixtures/wikipedia.gerber')
    end

    it "must return correct bounds" do
	Gerber.read('test/fixtures/example1.gerber').bounds.must_equal Rectangle.new -0.005.inch, -0.005.inch, 10.995.inch, 10.995.inch
    end

    it "must return the correct size" do
	Gerber.read('test/fixtures/example1.gerber').size.must_equal Geometry::Size[11.inch,11.inch]
    end

    describe "when reading Example 1 from the specification" do
	let(:gerber) { Gerber.read('test/fixtures/example1.gerber') }

	it "must create a Gerber object" do
	    gerber.must_be_instance_of(Gerber)
	end

	it "must have the correct name" do
	    gerber.name.must_equal 'Boxes'
	end

	it "must have only 1 layer" do
	    gerber.layers.count.must_equal 1
	end
    end

    it "must read Example 2 from the specification" do
	skip "There's an error in the example"
	Gerber.read('test/gerber/example2.gerber')
	gerber.layers.last.name.must_equal "BOXES"
    end

    it "must reject files with an M02 before the EOF" do
	lambda { Gerber.read('test/gerber/m02_not_at_end.gerber') }.must_raise Gerber::ParseError
    end

    describe "when reading" do
	describe "an empty file" do
	    let(:gerber) { Gerber.read 'test/fixtures/empty_millimeter.gerber' }

	    it "must set the units" do
		gerber.units.must_equal :millimeter
	    end
	end

	it "a file with aperture macros with fixed modifiers" do
	    Gerber.read('test/fixtures/macro_fixed.gerber').aperture_macros.size.must_equal 1
	end
    end

    describe "when unparsing" do
	let(:gerber) { Gerber.new }
	let(:testIO) { StringIO.new }

	it "must refuse invalid units" do
	    lambda { gerber.unparse(testIO) }.must_raise StandardError
	end

	describe "when the units are set" do
	    before do
		gerber.set_millimeter
	    end

	    it "must refuse an invalid zero omission mode" do
		lambda { gerber.unparse testIO }.must_raise StandardError
	    end

	    describe "when the zero omission mode is set" do
		before do
		    gerber.zero_omission = :leading
		end

		it "must refuse an invalid coordinate format" do
		    lambda { gerber.unparse testIO }.must_raise StandardError
		end

		describe "when the coordinate format is set" do
		    before do
			gerber.coordinate_format = 2,6
		    end

		    it "must unparse a simple image" do
			gerber.unparse testIO
			testIO.string.must_equal File.read('test/fixtures/empty_millimeter.gerber')
		    end
		end
	    end
	end

	describe "when the units are set to inches" do
	    before do
		gerber.set_inch
		gerber.coordinate_format = 2,6
		gerber.zero_omission = :leading
	    end

	    it "must write simple file" do
		gerber.unparse testIO
		testIO.string.must_equal File.read('test/fixtures/empty_inch.gerber')
	    end
	end

	describe "when the units are set to millimeters" do
	    before do
		gerber.set_millimeter
		gerber.coordinate_format = 2,6
		gerber.zero_omission = :leading
	    end

	    it "must unparse a simple image" do
		gerber.unparse testIO
		testIO.string.must_equal File.read('test/fixtures/empty_millimeter.gerber')
	    end
	end

	describe "when the image has a single level" do
	    before do
		gerber.name = 'Two_Boxes'
		gerber.set_inch
		gerber.coordinate_format = 2,6
		gerber.zero_omission = :leading

		aperture = gerber.new_aperture :circle => 0.01
		level = gerber.new_level
		level.add_line(aperture, [0,0], [5,0])
		level.add_line(aperture, [5,0], [5,5])
		level.add_line(aperture, [5,5], [0,5])
		level.add_line(aperture, [0,5], [0,0])

		level.add_line(aperture, [6,0], [11,0])
		level.add_line(aperture, [11,0], [11,5])
		level.add_line(aperture, [11,5], [6,5])
		level.add_line(aperture, [6,5], [6,0])
	    end

	    it "must unparse it" do
		gerber.unparse testIO
		testIO.string.must_equal File.read('test/fixtures/two_boxes.gerber')
	    end
	end

	it "must unparse an image with macros with fixed modifiers" do
	    Gerber.read('test/fixtures/macro_fixed.gerber').unparse testIO
	    testIO.string.must_equal File.read('test/fixtures/macro_fixed.gerber')
	end

	it "must unparse an image with macros with fixed modifiers and comments" do
	    Gerber.read('test/fixtures/macro_fixed_comment.gerber').unparse testIO
	    testIO.string.must_equal File.read('test/fixtures/macro_fixed_comment.gerber')
	end

	it "must unparse an image with macros with variable definitions" do
	    Gerber.read('test/fixtures/macro_rectroundedcorners.gerber').unparse testIO
	    testIO.string.must_equal File.read('test/fixtures/macro_rectroundedcorners.gerber')
	end

	it "must unparse an image with macros with variable modifiers" do
	    Gerber.read('test/fixtures/macro_variable.gerber').unparse testIO
	    testIO.string.must_equal File.read('test/fixtures/macro_variable.gerber')
	end
    end
end