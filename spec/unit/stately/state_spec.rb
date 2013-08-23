require 'spec_helper'

describe Stately::State do
  describe 'initialize' do
    describe 'with an unrecognized action' do
      it 'should not have an empty string for an action' do
        state = Stately::State.new :pending
        state.action.should_not == ""
      end
    end

    describe 'with a block given' do
      describe 'new' do
        before do
          @state = Stately::State.new(:invalid, nil) do
            allow_from :completed
            prevent_from :completed, :refunded

            before_transition :do => :prepare
            before_transition :from => :processing, :do => :before_completed
            after_transition :do => :cleanup
            after_transition :from => :processing, :do => :after_processing

            validate :validates_amount
            validate :validates_credit_card
          end
        end

        it 'should set initial values' do
          @state.name.should == :invalid

          @state.allow_from_states.should == [:completed]
          @state.prevent_from_states.should == [:completed, :refunded]

          @state.before_transitions.should == [{:do => :prepare}, {:from => :processing,
            :do => :before_completed}]
          @state.after_transitions.should == [{:do => :cleanup}, {:from => :processing,
            :do => :after_processing}]
          @state.validations.should == [:validates_amount, :validates_credit_card]
        end
      end
    end

    describe 'without a block given' do
      describe 'new' do
        before do
          @state = Stately::State.new(:test_state)
        end

        it 'should set initial values' do
          @state.name.should == :test_state

          @state.allow_from_states.should == []
          @state.prevent_from_states.should == []

          @state.before_transitions.should == []
          @state.after_transitions.should == []
          @state.validations.should == []
        end
      end

      describe 'with a given action' do
        before do
          @state = Stately::State.new(:test_state, :test_action)
        end

        it 'should set the given action name' do
          @state.action.should == 'test_action'
        end
      end

      describe 'without a given action' do
        before do
          @actions = { :completed => :complete, :converting => :convert, :invalid => :invalidate,
            :preparing => :prepare, :processing => :process, :refunded => :refund, :reticulating => :reticulate,
            :saving => :save, :searching => :search, :started => :start, :stopped => :stop }
        end

        it 'should set the correct action verb' do
          @actions.map do |state_name, action_name|
            state = Stately::State.new(state_name)
            state.action.should == action_name.to_s
          end
        end
      end
    end
  end

  describe '#to_s' do
    before do
      @state = Stately::State.new(:test_state)
    end

    it 'should return a string' do
      @state.to_s.should == 'test_state'
    end
  end

  describe '#to_sym' do
    before do
      @state = Stately::State.new('test_state')
    end

    it 'should return a symbol' do
      @state.to_sym.should == :test_state
    end
  end
end
