require 'minitest/autorun'
require 'gerber/layer/unparser'

describe Gerber::Layer::Unparser do
    let(:layer) { Gerber::Layer.new }
    let(:unparser) { Gerber::Layer::Unparser.new layer }

    describe "when formatting a G01 code" do
	before do
	    unparser.integer_places = 2
	    unparser.decimal_places = 6
	end

	describe "when the dcode is 1" do
	    before do
		unparser.instance_variable_set '@position', Point[1,2]
	    end

	    describe "when the X coordinate is the same as the current position" do
		it "must format properly" do
		    unparser.format_g1(1,3,1).must_equal 'G01Y3000000D01*'
		end
	    end

	    describe "when the Y coordinatte is the same as the current position" do
		it "must format properly" do
		    unparser.format_g1(3,2,1).must_equal 'G01X3000000D01*'
		end
	    end

	    describe "when both the X and Y coordinates are the same as the current position" do
		it "must format properly" do
		    unparser.format_g1(1,2,1).must_equal 'G01D01*'
		end
	    end
	end

	describe "when the dcode is 2" do
	    before do
		unparser.instance_variable_set '@position', Point[1,2]
	    end

	    describe "when the X coordinate is the same as the current position" do
		it "must format properly" do
		    unparser.format_g1(1,3,2).must_equal 'Y3000000D02*'
		end
	    end

	    describe "when the Y coordinatte is the same as the current position" do
		it "must format properly" do
		    unparser.format_g1(3,2,2).must_equal 'X3000000D02*'
		end
	    end

	    describe "when both the X and Y coordinates are the same as the current position" do
		it "must format properly" do
		    unparser.format_g1(1,2,2).must_equal 'D02*'
		end
	    end
	end

	describe "when the dcode is 3" do
	    before do
		unparser.instance_variable_set '@position', Point[1,2]
	    end

	    describe "when the X coordinate is the same as the current position" do
		it "must format properly" do
		    unparser.format_g1(1,3,3).must_equal 'Y3000000D03*'
		end
	    end

	    describe "when the Y coordinatte is the same as the current position" do
		it "must format properly" do
		    unparser.format_g1(3,2,3).must_equal 'X3000000D03*'
		end
	    end

	    describe "when both the X and Y coordinates are the same as the current position" do
		it "must format properly" do
		    unparser.format_g1(1,2,3).must_equal 'D03*'
		end
	    end
	end
    end
end
