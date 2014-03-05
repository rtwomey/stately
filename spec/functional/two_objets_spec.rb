require 'ostruct'
require 'spec_helper'

describe "two objects" do
  class1 = Class.new(OpenStruct) do
    stately :start => :object1_started, :attr => :object1_state do
      state :object1_processed, :action => :processed do
        allow_from :object1_started
      end
    end
  end

  class2 = Class.new(OpenStruct) do
    stately :start => :object2_started, :attr => :object2_state do
      state :object2_processed, :action => :processed do
        allow_from :object2_started
      end
    end
  end

  context "should have individual state" do
    let!(:object1) { class1.new }
    let!(:object2) { class2.new }

    it "object1 should get the value of object1_state" do
      object1.respond_to?(:object1_state).should be_true
    end

    it "object2 should get the value of object2_state" do
      object2.respond_to?(:object2_state).should be_true
    end
  end
end
