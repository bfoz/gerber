require 'minitest/autorun'
require 'gerber/aperture'

describe Gerber::Aperture do
    Aperture = Gerber::Aperture
    Rectangle = Aperture::Rectangle
    Size = Aperture::Size

    describe "when the aperture is a Circle" do
	let(:aperture) { Aperture.new(circle:2) }

	it "must have bounds" do
	    aperture.bounds.must_equal Rectangle.new Size[2,2]
	end

	it "must have a size" do
	    aperture.size.must_equal Size[2,2]
	end
    end

    describe "when the aperture is an Obround" do
	let(:aperture) { Aperture.new(obround:[2,4]) }

	it "must have bounds" do
	    aperture.bounds.must_equal Rectangle.new Size[2,4]
	end

	it "must have a size" do
	    aperture.size.must_equal Size[2,4]
	end
    end

    describe "when the aperture is a Polygon" do
	let(:aperture) { Aperture.new(polygon:2, sides:6) }

	it "must have bounds" do
	    aperture.bounds.must_equal Rectangle.new Size[2,2]
	end

	it "must have a size" do
	    aperture.size.must_equal Size[2,2]
	end
    end

    describe "when the aperture is a Rectangle" do
	let(:aperture) { Aperture.new(rectangle:[2,4]) }

	it "must have bounds" do
	    aperture.bounds.must_equal Rectangle.new Size[2,4]
	end

	it "must have a size" do
	    aperture.size.must_equal Size[2,4]
	end
    end

    describe "when converted to a string" do
	let(:circle_hole) { 0.02 }
	let(:square_hole) { {:x => 0.02, :y => 0.03} }

	describe "when circle" do
	    let(:aperture) { Aperture.new :circle => 0.01 }

	    it "with no hole" do
		aperture.to_s.must_equal 'C,0.01'
	    end

	    it "with a round hole" do
		aperture.hole = circle_hole
		aperture.to_s.must_equal 'C,0.01X0.02'
	    end

	    it "with a square hole" do
		aperture.hole = square_hole
		aperture.to_s.must_equal 'C,0.01X0.02X0.03'
	    end
	end

	describe "when obround" do
	    let(:aperture) { Aperture.new :obround => [0.01, 0.02] }

	    it "without a hole" do
		aperture.to_s.must_equal 'O,0.01X0.02'
	    end

	    it "with a round hole" do
		aperture.hole = circle_hole
		aperture.to_s.must_equal 'O,0.01X0.02X0.02'
	    end

	    it "with a square hole" do
		aperture.hole = square_hole
		aperture.to_s.must_equal 'O,0.01X0.02X0.02X0.03'
	    end
	end

	describe "when rectangle" do
	    let(:aperture) { Aperture.new :rectangle => [0.01, 0.03] }

	    it "without a hole" do
		aperture.to_s.must_equal 'R,0.01X0.03'
	    end

	    it "with a round hole" do
		aperture.hole = circle_hole
		aperture.to_s.must_equal 'R,0.01X0.03X0.02'
	    end

	    it "with a square hole" do
		aperture.hole = square_hole
		aperture.to_s.must_equal 'R,0.01X0.03X0.02X0.03'
	    end
	end

	describe "when polygon" do
	    let(:aperture) { Aperture.new :polygon => 0.01, :sides => 6 }

	    describe "when rotated" do
		before do
		    aperture.rotation = 90
		end

		it "with no hole" do
		    aperture.to_s.must_equal 'P,0.01X6X90'
		end

		it "with a round hole" do
		    aperture.hole = circle_hole
		    aperture.to_s.must_equal 'P,0.01X6X90X0.02'
		end

		it "with a square hole" do
		    aperture.hole = square_hole
		    aperture.to_s.must_equal 'P,0.01X6X90X0.02X0.03'
		end
	    end

	    describe "when not rotated" do
		it "with no hole" do
		    aperture.to_s.must_equal 'P,0.01X6'
		end

		it "with a round hole" do
		    aperture.hole = circle_hole
		    aperture.to_s.must_equal 'P,0.01X6X0X0.02'
		end

		it "with a square hole" do
		    aperture.hole = square_hole
		    aperture.to_s.must_equal 'P,0.01X6X0X0.02X0.03'
		end
	    end
	end
    end
end
