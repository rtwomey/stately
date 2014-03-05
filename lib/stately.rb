require 'stately/machine'
require 'stately/state'

module Stately
  # An InvalidTransition is an error that is raised when attempting to transition from a state
  # that's not allowable, based on the Stately::State DSL definitions allow_from and prevent_from.
  class InvalidTransition < StandardError
  end

  module Core
    # Define a new Stately state machine.
    #
    # As an example, let's say you have an Order object and you'd like an elegant state machine for
    # it. Here's one way you might set it up:
    #
    #     Class Order do
    #       stately start: :processing do
    #         state :completed do
    #           prevent_from :refunded
    #
    #           before_transition from: :processing, do: :calculate_total
    #           after_transition do: :email_receipt
    #
    #           validate :validates_credit_card
    #         end
    #
    #         state :invalid do
    #           prevent_from :completed, :refunded
    #         end
    #
    #         state :refunded do
    #           allow_from :completed
    #
    #           after_transition do: :email_receipt
    #         end
    #       end
    #     end
    #
    # This example is doing quite a few things, paraphrased as:
    #
    #   * It sets up a new state machine using the default state attribute on Order to store the
    #     current state. It also indicates the initial state should be :processing.
    #   * It defines three states: :completed, :refunded, and :invalid
    #   * Order can transition to the completed state from all but the refunded state. Similar
    #     definitions are setup for the other two states.
    #   * Callbacks are setup using before_transition and after_transition
    #   * Validations are added. If a validation fails, it prevents the transition.
    #
    # Stately tries hard not to surprise you. In a typical Stately implementation, you'll always have
    # an after_transition, primarily to call save (or whatever the equivalent is to store the
    # instance's current state).
    def stately(*opts, &block)
      options = opts.last.is_a?(Hash) ? opts.last : {}
      options[:attr] ||= :state

      @stately_machine = Stately::Machine.new(options[:attr], options[:start])
      @stately_machine.instance_eval(&block) if block_given?

      include Stately::InstanceMethods
    end

    # Get the current Stately::Machine object
    def stately_machine
      self.instance_variable_get(:@stately_machine)
    end

    # Set the current Stately::Machine object
    def stately_machine=(obj)
      @stately_machine = obj
    end
  end

  module InstanceMethods
    # Sets up an object with Stately. The DSL is parsed and the Stately::Machine is initialized.
    #
    # When an object is first initialized, Stately automatically sets the state attribute to the
    # start state.
    #
    # Additionally, a method is defined for each of the state's actions. These methods are used to
    # transition between states. If you have a state named 'completed', Stately will infer the
    # action to be 'complete' and define a method named 'complete'. You can then call 'complete' on
    # the object to transition into the completed state.

    def InstanceMethods.included(klass)
      klass.class_eval do
        alias_method :init_instance, :initialize
        def initialize(*args)
          init_instance(*args)
          initialize_stately
        end

        stately_machine.states.each do |state|
          define_method(state.action) do
            transition_to(state)
          end

          define_method(:"#{state.name}?") do
            send(stately_machine.state_attr) == state.name.to_s
          end
        end
      end
    end

    # @return [Array<String>] a list of state names.
    def states
      stately_machine.states.map(&:name)
    end

    private

    def stately_machine
      self.class.stately_machine
    end

    def allowed_state_transition?(to_state)
      if current_state == to_state.to_s
        raise InvalidTransition,
          "Prevented transition from #{current_state} to #{state.to_s}."
      end

      allowed_from_states(to_state).include?(current_state.to_sym)
    end

    def allowed_from_states(state)
      if state.allow_from_states.empty?
        stately_machine.states.map(&:to_sym) - state.prevent_from_states
      else
        state.allow_from_states
      end
    end

    def current_state
      (self.send(stately_machine.state_attr) || stately_machine.start).to_s
    end

    def eligible_callback?(callback)
      if (callback.has_key?(:from) && callback[:from].to_s == current_state) ||
        (!callback.has_key?(:from))
        true
      else
        false
      end
    end

    def initialize_stately
      set_initial_state
    end

    def run_before_transition_callbacks(state)
      state.before_transitions.each do |callback|
        if eligible_callback?(callback)
          self.send callback[:do]
        end
      end
    end

    def run_after_transition_callbacks(state)
      state.after_transitions.each do |callback|
        self.send callback[:do]
      end
    end

    def state_named(state_name)
      stately_machine.states.find { |s| s.to_s == state_name.to_s }
    end

    def transition_to(state_name)
      state = state_named(state_name)

      if valid_transition_to?(state)
        run_before_transition_callbacks(state)
        write_model_attribute(stately_machine.state_attr, state.to_s)
        run_after_transition_callbacks(state)
      end
    end

    def set_initial_state
      write_model_attribute(stately_machine.state_attr, stately_machine.start.to_s)
    end

    def write_model_attribute(attr, val)
      send("#{attr}=", val)
    end

    def valid_transition_to?(state)
      if allowed_state_transition?(state)
        if state.validations.nil? || state.validations.empty?
          true
        else
          results = state.validations.collect do |validation|
            self.send validation
          end

          results.detect { |r| r == false }.nil?
        end
      else
        raise InvalidTransition,
          "Prevented transition from #{current_state} to #{state.to_s}."
      end
    end
  end
end

require 'stately/core_ext'
