require 'spec_helper'

describe HopHop::Helper do
  it 'should underscore' do
    HopHop::Helper.underscore('CamelCase').should == 'camel_case'
    HopHop::Helper.underscore('NameSpaced::CamelCase').should == 'name_spaced/camel_case'
  end

  it 'shold camelize' do
    HopHop::Helper.camelize('camel_case').should == 'CamelCase'
    HopHop::Helper.camelize('name_spaced/camel_case').should == 'NameSpaced::CamelCase'
  end

  it 'should constantize' do
    HopHop::Helper.constantize('Math::PI').should == Math::PI
    HopHop::Helper.constantize('IO::SYNC').should == IO::SYNC
  end

  it 'should slice a hash' do
    tmp = { foo: 1, bar: 2, baz: 'lorem' }
    expect(HopHop::Helper.slice_hash(tmp, :foo, :bar)).to include(foo: 1, bar: 2)
    expect(HopHop::Helper.slice_hash(tmp, :foo, :bar)).to_not include(baz: 'lorem')
    expect(HopHop::Helper.slice_hash(tmp, :bar, :baz)).to include(bar: 2, baz: 'lorem')
    expect(HopHop::Helper.slice_hash(tmp, :bar, :baz)).to_not include(foo: 1)
  end
end
