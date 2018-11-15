require 'spec_helper'
describe 'linux_disable_ipv6' do
  context 'with default values for all parameters' do
    it { should contain_class('linux_disable_ipv6') }
  end
end
