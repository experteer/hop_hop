require 'spec_helper'

describe HopHop::Helper do
  it "should underscore" do
    expect(HopHop::Helper.underscore("CamelCase")).to eql('camel_case')
    expect(HopHop::Helper.underscore("NameSpaced::CamelCase")).to eql('name_spaced/camel_case')
  end

  it "shold camelize" do
    expect(HopHop::Helper.camelize("camel_case")).to eql("CamelCase")
    expect(HopHop::Helper.camelize("name_spaced/camel_case")).to eql("NameSpaced::CamelCase")
  end

  it "should constantize" do
    expect(HopHop::Helper.constantize("Math::PI")).to eql(Math::PI)
    expect(HopHop::Helper.constantize("IO::SYNC")).to eql(IO::SYNC)
  end

  it "should slice a hash" do
    tmp = { :foo => 1, :bar => 2, :baz => 'lorem' }
    expect(HopHop::Helper.slice_hash(tmp, :foo, :bar)).to include(:foo => 1, :bar => 2)
    expect(HopHop::Helper.slice_hash(tmp, :foo, :bar)).to_not include(:baz => 'lorem')
    expect(HopHop::Helper.slice_hash(tmp, :bar, :baz)).to include(:bar => 2, :baz => 'lorem')
    expect(HopHop::Helper.slice_hash(tmp, :bar, :baz)).to_not include(:foo => 1)
  end
end
