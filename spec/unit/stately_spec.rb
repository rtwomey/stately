require 'ostruct'
require 'spec_helper'

describe Stately::InstanceMethods do
  before do
    @test_class = Class.new(Object) do
      attr_accessor :state

      stately :start => :processing do
        state :completed
      end
    end

    @object = @test_class.new
  end

  describe 'initialize' do
    it 'creates a new Stately::Machine' do
      @object.class.stately_machine.class.should == Stately::Machine
      @object.class.stately_machine.should == @test_class.stately_machine
    end

    it 'sets initial state' do
      @object.state.should == 'processing'
    end
  end

  describe '#states' do
    it 'returns known state names in order' do
      @object.states.should == [:processing, :completed]
    end
  end

  describe 'actions' do
    it 'defines action methods' do
      @test_class.method_defined?(:complete).should be_true
      @test_class.method_defined?(:process).should be_true
    end

    it 'defines test methods' do
      @test_class.method_defined?(:processing?).should be_true
      @test_class.method_defined?(:completed?).should be_true
    end
  end

  describe 'stately_machine' do
    it 'defines a class-level accessor called stately_machine' do
      @test_class.respond_to?(:stately_machine).should be_true
    end

    it 'defines an instance-level accessor called stately_machine' do
      @test_class.class.method_defined?(:stately_machine).should be_true
    end

    it 'defines a class-level setter called stately_machine=' do
      @test_class.class.respond_to?(:stately_machine=).should be_true
    end

    it 'defines an instance-level setter called stately_machine=' do
      @test_class.method_defined?(:stately_machine=).should be_true
    end
  end
end
