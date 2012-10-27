require 'stately/machine'
require 'stately/state'

module Stately
  class InvalidTransition < StandardError
  end

  def stately(*opts, &block)
    options = opts.last.is_a?(Hash) ? opts.last : {}
    options[:attr] ||= :state

    self.stately_machine = Stately::Machine.new(options[:attr], options[:start])
    self.stately_machine.instance_eval(&block) if block_given?

    include Stately::InstanceMethods
  end

  def self.stately_machine
    @@stately_machine
  end

  def stately_machine
    @@stately_machine
  end

  def self.stately_machine=(obj)
    @@stately_machine = obj
  end

  def stately_machine=(obj)
    @@stately_machine = obj
  end

  module InstanceMethods
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
        end
      end
    end

    def states
      stately_machine.states.map(&:name)
    end

    private

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
        write_attribute(stately_machine.state_attr, state.to_s)
        run_after_transition_callbacks(state)
      end
    end

    def set_initial_state
      write_attribute(stately_machine.state_attr, stately_machine.start.to_s)
    end

    def write_attribute(attr, val)
      send("#{attr}=", val)
    end

    def valid_transition_to?(state)
      # check this is an allowed state to transition from
      if allowed_state_transition?(state)
        # check validations
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
