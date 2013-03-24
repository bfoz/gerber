require 'minitest/autorun'
require 'gerber/aperture_macro'

describe Gerber::ApertureMacro do
    ApertureMacro = Gerber::ApertureMacro

    let (:macro) { ApertureMacro.new "TestMacro" }

    describe "when initialized with a name" do
	it "must have a name" do
	    macro.name.must_equal "TestMacro"
	end

	it "must not have any primitives" do
	    macro.primitives.size.must_equal 0
	end
    end

    describe "when primitives with fixed modifiers" do
	describe "when pushing a primitive" do
	    it "must push a Comment" do
		macro.push_comment "This is a comment"
		macro.primitives.last.must_be_kind_of Gerber::ApertureMacro::Comment
		macro.primitives.last.text.must_equal "This is a comment"
	    end

	    it "must push a Circle" do
		macro.push_primitive 1,1,1.5,0,0
		macro.primitives.last.must_be_kind_of Gerber::ApertureMacro::Circle
	    end

	    it "must push a Definition" do
		macro.push_definition '$1', '$1+$2'
		macro.primitives.last.must_be_kind_of Gerber::ApertureMacro::Definition
		macro.primitives.last.variable.must_equal '$1'
		macro.primitives.last.expression.must_equal '$1+$2'
	    end

	    it "must push a Line" do
		macro.push_primitive 20,1,0.9,0,0.45,12,0.45,0
		macro.primitives.last.must_be_kind_of Gerber::ApertureMacro::Line
	    end

	    it "must push a Centered Line" do
		macro.push_primitive 21,1,6.8,1.2,3.4,0.6,0
		macro.primitives.last.must_be_kind_of Gerber::ApertureMacro::CenteredLine
	    end

	    it "must push an Origin Line" do
		macro.push_primitive 22,1,6.8,1.2,0,0,0
		macro.primitives.last.must_be_kind_of Gerber::ApertureMacro::OriginLine
	    end

	    it "must push an Outline" do
		macro.push_primitive 4,1,4,0.1,0.1,0.5,0.1,0.5,0.5,0.1,0.5,0.1,0.1,0
		macro.primitives.last.must_be_kind_of Gerber::ApertureMacro::Outline
		macro.primitives.last.points.count.must_equal 5
		macro.primitives.last.points.last.must_equal Geometry::Point[0.1,0.1]
	    end

	    it "must push a Polygon" do
		macro.push_primitive 5,1,8,0,0,8,0
		macro.primitives.last.must_be_kind_of Gerber::ApertureMacro::Polygon
	    end

	    it "must push a Moire" do
		macro.push_primitive 6,0,0,5,0.5,0.5,2,0.1,6,0
		macro.primitives.last.must_be_kind_of Gerber::ApertureMacro::Moire
	    end

	    it "must push a Thermal" do
		macro.push_primitive 7,1,2,4,3,0,0
		macro.primitives.last.must_be_kind_of Gerber::ApertureMacro::Thermal
	    end
	end

	describe "when converting to an Array" do
	    it "must convert a Comment" do
		macro.push_comment "This is a comment"
		macro.to_a.must_equal ['0 This is a comment*']
	    end

	    it "must convert a Circle" do
		macro.push_primitive 1,1,1.5,0,0
		macro.to_a.must_equal ['1,1,1.5,0,0*']
	    end

	    it "must convert a Line" do
		macro.push_primitive 20,1,0.9,0,0.45,12,0.45,0
		macro.to_a.must_equal ['2,1,0.9,0,0.45,12,0.45,0*']
	    end

	    it "must convert a Centered Line" do
		macro.push_primitive 21,1,6.8,1.2,3.4,0.6,0
		macro.to_a.must_equal ['21,1,6.8,1.2,3.4,0.6,0*']
	    end

	    it "must convert an Origin Line" do
		macro.push_primitive 22,1,6.8,1.2,0,0,0
		macro.to_a.must_equal ['22,1,6.8,1.2,0,0,0*']
	    end

	    it "must convert an Outline" do
		macro.push_primitive 4,1,4,0.1,0.1,0.5,0.1,0.5,0.5,0.1,0.5,0.1,0.1,0
		macro.to_a.must_equal ['4,1,4,0.1,0.1,0.5,0.1,0.5,0.5,0.1,0.5,0.1,0.1,0*']
	    end

	    it "must convert a Polygon" do
		macro.push_primitive 5,1,8,0,0,8,0
		macro.to_a.must_equal ['5,1,8,0,0,8,0*']
	    end

	    it "must convert a Moire" do
		macro.push_primitive 6,0,0,5,0.5,0.5,2,0.1,6,0
		macro.to_a.must_equal ['6,0,0,5,0.5,0.5,2,0.1,6,0*']
	    end

	    it "must convert a Thermal" do
		macro.push_primitive 7,1,2,4,3,0,0
		macro.to_a.must_equal ['7,1,2,4,3,0,0*']
	    end
	end
    end

    describe "when primitives with variable modifiers" do
	let(:variable1) { Gerber::ApertureMacro::Variable.new }
	let(:variable2) { Gerber::ApertureMacro::Variable.new }

	before do
	    macro.modifiers = [nil, variable1, variable2]
	end

	describe "when pushing a primitive" do
	    it "must push a Circle" do
		macro.push_primitive 1,1,1.5,variable1,0
		macro.primitives.last.must_be_kind_of Gerber::ApertureMacro::Circle
	    end
	end

	describe "when converting to an Array" do
	    it "must convert a Circle" do
		macro.push_primitive 1,1,1.5,variable1,0
		macro.to_a.must_equal ['1,1,1.5,$1,0*']
	    end

	    it "must convert an Outline" do
		macro.push_primitive 4,1,4,0.1,0.1,0.5,variable2,0.5,0.5,0.1,variable1,0.1,0.1,0
		macro.to_a.must_equal ['4,1,4,0.1,0.1,0.5,$2,0.5,0.5,0.1,$1,0.1,0.1,0*']
	    end
	end
    end
end
