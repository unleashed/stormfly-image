require 'spec_helper'

module StormFly
  describe Image do
    it 'should have a version number' do
      Image::VERSION.should_not be_nil
    end
  end
end
