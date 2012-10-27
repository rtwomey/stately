# Stately

An elegant state machine for your ruby objects.

![A stately fellow.](https://dl.dropbox.com/u/2754528/exquisite_cat.jpg "A stately fellow.")

## Making a stately start

Stately is a state machine for ruby objects, with an elegant, easy-to-read DSL. Here's an example showing off what Stately can do:

    Class Order do
      stately start: :processing do
        state :completed do
          prevent_from :refunded

          before_transition from: :processing, do: :calculate_total
          after_transition do: :email_receipt

          validate :validates_credit_card
        end

        state :invalid do
          prevent_from :completed, :refunded
        end

        state :refunded do
          allow_from :completed

          after_transition do: :email_receipt
        end
      end

Stately tries hard not to surprise you. When you transition to a new state, you're responsible for taking whatever actions that means using `before_transition` and `after_transition`. Stately also has no dependencies on things like DataMapper or ActiveModel, so it will never surprise you with an implicit `save` after transitioning states.

## Getting started

Either install locally:

    gem install stately

or add it to your Gemfile:

    gem stately

Be sure to run `bundle install` afterwards.

The first step is to add the following to your object:

    stately start: :initial_state, attr: :my_state_attr do
      # ...
    end

This sets up Stately to look for an attribute named `my_state_attr`, and initially set it to `initial_state`. If you omit `attr: :my_state_attr`, Stately will automatically look for an attribute named `state`.

## Defining a state

States make up the core of Stately and define two things: the name of the state (i.e. "completed"), and a verb as the name of the method to call to begin a transition into that state (i.e. "complete"). Stately has support for some common state/verb combinations, but you can always use your own:

    Class Order
      stately start: :processing do
        state :my_state, action: transition_to_my_state
      end
    end

    order = Order.new
    order.transition_to_my_state

## Transitions

A "transition" is the process of moving from one state to another. You can define legal transitions using `allow_from` and `prevent_from`:

    state :completed do
      allow_from :processing
      prevent_from :refunded
    end

In the above example, if you try to transition to `completed` (by calling `complete` on the object) from `refunded`, you'll see a `Stately::InvalidTransition` is raised. By default, all transitions are allowed.

## Validations

While transitioning from one state to another, you can define validations to be run. If any validation returns `false`, the transition is halted.

    state :completed do
      validate :validates_amount
      validate :validates_credit_card
    end

Each validation is also called in order, so first `validates_amount` will be called, and if it doesn't return `false`, then `validates_credit_card` will be called and checked.

## Callbacks

Callbacks can be defined to run either before or after a transition occurs. A `before_transition` is run after validations are checked, but before the `state_attr` has been written to with the new state. An `after_transition` is called after the `state_attr` has been written to.

If you're using Stately with a database, you'll almost always want an `after_transition` that calls `save` or the equivalent.

    state :completed do
      before_transition from: :processing, do: :before_completed
      before_transition from: :invalid, do: :cleanup_invalid
      after_transition do: :after_completed
    end

A callback can include an optional `from` state name, which is only called when transitioning from the named state. Omitting it means the callback is always called.

Additionally, each callback is executed in the order in which it's defined.

## Requirements

Stately requires Ruby 1.9+. If you'd like to contribute to Stately, you'll need Rspec 2.0+.

## License

Stately is Copyright © 2012 Ryan Twomey. It is free software, and may be redistributed under the terms specified in the MIT-LICENSE file.
