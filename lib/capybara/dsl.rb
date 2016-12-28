# frozen_string_literal: true
require 'capybara'

module Capybara
  module DSL
    def self.included(base)
      warn "including Capybara::DSL in the global scope is not recommended!" if base == Object
      base.define_singleton_method :include do |*args|
        args.select { |arg| !include?(arg) }.each do |arg|
          conflicts = arg.instance_methods & Capybara::Session::DSL_METHODS
          warn "Capybara::DSL methods #{conflicts} are shadowed by #{arg}. "\
               "If you expected this please add the method names to Capybara.expected_shadowed_dsl_methods and "\
               "make sure to always call those methods on a session object." if Capybara::DSL.unexpected_conflicts?(conflicts)
        end
        super(*args)
      end
    end

    def self.extended(base)
      warn "extending the main object with Capybara::DSL is not recommended!" if base == TOPLEVEL_BINDING.eval("self")
      super
    end

    ##
    #
    # Shortcut to working in a different session.
    #
    def using_session(name, &block)
      Capybara.using_session(name, &block)
    end

    ##
    #
    # Shortcut to using a different wait time.
    #
    def using_wait_time(seconds, &block)
      Capybara.using_wait_time(seconds, &block)
    end

    ##
    #
    # Shortcut to accessing the current session.
    #
    #     class MyClass
    #       include Capybara::DSL
    #
    #       def has_header?
    #         page.has_css?('h1')
    #       end
    #     end
    #
    # @return [Capybara::Session] The current session object
    #
    def page
      Capybara.current_session
    end

    Session::DSL_METHODS.each do |method|
      define_method method do |*args, &block|
        page.send method, *args, &block
      end
    end

  private
    def self.unexpected_conflicts?(conflicts)
      return false if Capybara.expected_shadowed_dsl_methods.nil? || conflicts.empty?
      !(conflicts - Capybara.expected_shadowed_dsl_methods).empty?
    end
  end

  extend(Capybara::DSL)
end
