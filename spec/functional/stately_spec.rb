require 'ostruct'
require 'spec_helper'

describe Stately do
  before do
    @order_class = Class.new(OpenStruct) do
      stately :start => :processing do
        state :completed do
          prevent_from :refunded

          before_transition :from => :processing, :do => :before_completed
          before_transition :from => :invalid, :do => :cleanup_invalid
          after_transition :do => :after_completed

          validate :validates_amount
          validate :validates_credit_card
        end

        state :invalid do
          prevent_from :completed, :refunded
        end

        state :processing do
          prevent_from :completed, :invalid, :refunded
        end

        state :refunded do
          allow_from :completed

          before_transition :from => :completed, :do => :before_refunded
          after_transition :from => :completed, :do => :after_refunded
        end
      end

      private

      def before_completed
        self.serial_number = Time.now.usec
      end

      def after_completed
      end

      def before_refunded
        self.refunded_reason = 'Overcharged'
      end

      def after_refunded
      end

      def cleanup_invalid
        self.serial_number = nil
      end

      def validates_amount
        amount > 0.0 && amount < 100.0
      end

      def validates_credit_card
        self.cc_number == 123
      end
    end
  end

  def self.should_call_callbacks_on_complete(order)
    @order = order

    describe 'callbacks' do
      it 'calls callbacks in order' do
        @order.should_receive(:before_completed).ordered
        @order.should_receive(:after_completed).ordered
        @order.should_not_receive :cleanup_invalid

        @order.complete
      end

      it 'sets serial_number' do
        @order.serial_number.should be_nil
        @order.complete
        @order.serial_number.should_not be_nil
      end
    end
  end

  def self.should_call_validations_on_complete(order)
    @order = order

    describe 'validations' do
      it 'calls validations in order' do
        @order.should_receive(:validates_amount).ordered
        @order.should_receive(:validates_credit_card).ordered

        @order.complete
      end

      describe 'return values' do
        before do
          @order.stub :validates_amount => false
        end

        it 'should halt on false' do
          @order.should_receive :validates_amount
          @order.should_receive :validates_credit_card
          @order.should_not_receive :before_completed
          @order.should_not_receive :after_completed
          @order.should_not_receive :cleanup_invalid

          current_state = @order.state
          @order.complete
          @order.state.should == current_state
        end
      end
    end
  end

  def self.should_prevent_transition(from, to, action)
    before do
      @order = @order_class.new(:amount => 99, :cc_number => 123)
      @order.state = from
    end

    it 'should be prevented' do
      lambda { @order.send(action) }.should raise_error(Stately::InvalidTransition,
        "Prevented transition from #{from} to #{to}.")
    end
  end

  def self.should_set_state(new_state, order, action)
    @order = order

    describe 'on success' do
      before do
        @order.send action
      end

      it 'sets state' do
        @order.state.should == new_state
      end

      it 'responds to test method' do
        @order.send("#{new_state}?").should be_true
      end
    end
  end

  describe 'initial state' do
    before do
      @order = @order_class.new(:amount => 99, :cc_number => 123)
    end

    it 'creates actions for each state' do
      @order_class.method_defined?(:complete).should be_true
      @order_class.method_defined?(:process).should be_true
      @order_class.method_defined?(:refund).should be_true
    end

    it 'creates tests for each state' do
      @order_class.method_defined?(:processing?).should be_true
      @order_class.method_defined?(:completed?).should be_true
      @order_class.method_defined?(:invalid?).should be_true
      @order_class.method_defined?(:refunded?).should be_true
    end

    it 'finds all states' do
      @order.states.should == [:completed, :invalid, :processing, :refunded]
    end

    it 'sets initial state to processing' do
      @order.state.should == 'processing'
    end
  end

  describe '#process' do
    describe 'from processing' do
      should_prevent_transition('processing', 'processing', :process)
    end

    describe 'from completed' do
      should_prevent_transition('completed', 'processing', :process)
    end

    describe 'from invalid' do
      should_prevent_transition('invalid', 'processing', :process)
    end

    describe 'from refunded' do
      should_prevent_transition('refunded', 'processing', :process)
    end
  end

  describe '#complete' do
    before do
      @order = @order_class.new(:amount => 99, :cc_number => 123)
    end

    describe 'from processing' do
      should_call_validations_on_complete(@order)

      describe 'callbacks' do
        it 'calls callbacks in order' do
          @order.should_receive(:before_completed).ordered
          @order.should_receive(:after_completed).ordered
          @order.should_not_receive :cleanup_invalid

          @order.complete
        end

        it 'sets serial_number' do
          @order.serial_number.should be_nil
          @order.complete
          @order.serial_number.should_not be_nil
        end
      end

      should_set_state('completed', @order, :complete)
    end

    describe 'from completed' do
      should_prevent_transition('completed', 'completed', :complete)
    end

    describe 'from invalid' do
      before do
        @order.serial_number = Time.now.usec
        @order.state = 'invalid'
      end

      should_call_validations_on_complete(@order)

      describe 'callbacks' do
        it 'calls callbacks in order' do
          @order.should_receive(:cleanup_invalid).ordered
          @order.should_receive(:after_completed).ordered
          @order.should_not_receive :before_completed

          @order.complete
        end

        it 'sets serial_number to nil' do
          @order.serial_number.should_not be_nil
          @order.complete
          @order.serial_number.should be_nil
        end
      end

      should_set_state('completed', @order, :complete)
    end

    describe 'from refunded' do
      should_prevent_transition('refunded', 'completed', :complete)
    end
  end

  describe '#invalidate' do
    describe 'from processing' do
      before do
        @order = @order_class.new(:amount => 99, :cc_number => 123)
        @order.invalidate
      end

      it 'sets state' do
        @order.state.should == 'invalid'
      end
    end

    describe 'from completed' do
      should_prevent_transition('completed', 'invalid', :invalidate)
    end

    describe 'from invalid' do
      should_prevent_transition('invalid', 'invalid', :invalidate)
    end

    describe 'from refunded' do
      should_prevent_transition('refunded', 'invalid', :invalidate)
    end
  end

  describe '#refund' do
    describe 'from processing' do
      should_prevent_transition('processing', 'refunded', :refund)
    end

    describe 'from completed' do
      before do
        @order = @order_class.new(:amount => 99, :cc_number => 123)
        @order.state = 'completed'
      end

      describe 'callbacks' do
        it 'calls callbacks in order' do
          @order.should_receive(:before_refunded).ordered
          @order.should_receive(:after_refunded).ordered

          @order.refund
        end

        it 'sets refunded_reason' do
          @order.refunded_reason.should be_nil
          @order.refund
          @order.refunded_reason.should_not be_nil
        end
      end

      should_set_state('refunded', @order, :refund)
    end

    describe 'from invalid' do
      should_prevent_transition('invalid', 'refunded', :refund)
    end

    describe 'from refunded' do
      should_prevent_transition('refunded', 'refunded', :refund)
    end
  end
end
