#!/usr/bin/env ruby -S rspec
require 'spec_helper'

describe Puppet::Parser::Functions.function(:compliance_map) do
  let(:scope) do
    PuppetlabsSpec::PuppetInternals.scope
  end

  subject do
    function_name = Puppet::Parser::Functions.function(:compliance_map)
    scope.method(function_name)
  end

  # Outside of this, I'm not sure how to actually fake out a lower scope.
  # The remainder of the tests are handled in rspec-puppet.
  context 'It should fail when called improperly' do
    it 'should only accept a String as the first parameter' do
      expect {
        subject.call([['string'],'string'])
      }.to raise_error(/First parameter must be .* String/)
    end

    it 'should only accept a String as the second parameter' do
      expect {
        subject.call(['string',['string']])
      }.to raise_error(/Second parameter must be .* String/)
    end

    it 'should only accept a String as the third parameter' do
      expect {
        subject.call(['string','string',['string']])
      }.to raise_error(/Third parameter must be .* String/)
    end

    it 'should require two parameters if any are given' do
      expect {
        subject.call(['string'])
      }.to raise_error(/at least two parameters/)
    end
  end
end
