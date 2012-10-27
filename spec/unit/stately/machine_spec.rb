require 'spec_helper'

describe Stately::Machine do
  before do
    @machine = Stately::Machine.new(:state, :processing)
  end

  describe 'initialize' do
    it 'sets initial vars' do
      @machine.start.should == :processing
      @machine.state_attr.should == :state
      @machine.states.map(&:to_s).should == ['processing']
    end

    it 'guesses the initial action' do
      @machine.states.first.action.should == 'process'
    end
  end

  describe '#state' do
    describe 'with name only' do
      describe 'of a new state' do
        before do
          @machine.state(:completed)
        end

        it 'adds a new state' do
          @machine.states.map(&:to_s).should == ['processing', 'completed']
        end
      end

      describe 'of a previously defined state' do
        before do
          @machine.state(:processing)
        end

        it "doesn't add a new state" do
          @machine.states.map(&:to_s).should == ['processing']
        end
      end
    end

    describe 'with name and action' do
      describe 'of a new state' do
        before do
          @machine.state(:new_state, action: :transition_to_new_state)
        end

        it 'adds a new state' do
          @machine.states.map(&:to_s).should == ['processing', 'new_state']
        end

        it 'adds the correct action to the new state' do
          @machine.states.last.action.should == 'transition_to_new_state'
        end
      end

      describe 'of a previously defined state' do
        before do
          @machine.state(:processing, action: :transition_to_processing)
        end

        it "doesn't add a new state" do
          @machine.states.map(&:to_s).should == ['processing']
        end

        it 'adds the correct action to the existing state' do
          @machine.states.first.action.should == 'transition_to_processing'
        end
      end
    end

    describe 'with name, action, and block' do
      describe 'of a new state' do
        before do
          @machine.state(:new_state, action: :transition_to_new_state) do
            allow_from :completed
          end

          @new_state = @machine.states.last
        end

        it 'adds a new state' do
          @machine.states.map(&:to_s).should == ['processing', 'new_state']
        end

        it 'adds the correct action to the new state' do
          @new_state.action.should == 'transition_to_new_state'
        end

        it 'includes the allow_from param' do
          @new_state.allow_from_states.should == [:completed]
        end
      end

      describe 'of a previously defined state' do
        before do
          @machine.state(:processing, action: :transition_to_processing) do
            allow_from :completed
          end

          @new_state = @machine.states.last
        end

        it "doesn't add a new state" do
          @machine.states.map(&:to_s).should == ['processing']
        end

        it 'adds the correct action to the new state' do
          @new_state.action.should == 'transition_to_processing'
        end

        it 'includes the allow_from param' do
          @new_state.allow_from_states.should == [:completed]
        end
      end
    end
  end
end
