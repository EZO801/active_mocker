# frozen_string_literal: true
require "colorize"
module ActiveMocker
  class DisplayErrors
    attr_reader :errors, :klass_count, :out
    attr_accessor :success_count, :failed_classes, :klass_count

    def initialize(klass_count: nil, out: STDERR)
      @errors         = []
      @success_count  = 0
      @klass_count    = klass_count
      @failed_classes = []
      @out            = out
    end

    def add(errors)
      @errors.concat([*errors])
    end

    def wrap_errors(errors, model_name, type: nil)
      add errors.map { |e| ErrorObject.build_from(object: e, class_name: model_name, type: type ? type : e.try(:type)) }
    end

    def wrap_an_exception(e, model_name)
      add ErrorObject.build_from(exception: e, class_name: model_name)
    end

    def uniq_errors
      @uniq_errors ||= errors.flatten.compact.uniq.sort_by(&:class_name)
    end

    def any_errors?
      uniq_errors.count > 0
    end

    def display_errors
      uniq_errors.each do |e|
        next unless ENV["DEBUG"] || !(e.level == :debug)

        display_verbosity_three(e) || display_verbosity_two(e)
      end

      display_verbosity_one
    end

    def error_summary
      display "Error Summary"
      display "errors: #{error_count}, warn: #{warn}, info: #{info}"
      display "Failed models: #{failed_classes.join(", ")}" if failed_classes.count > 0
    end

    def failure_count_message
      if success_count < klass_count || any_errors?
        display "#{klass_count - success_count} mock(s) out of #{klass_count} failed."
      end
    end

    private

    def display(msg)
      out.puts(msg)
    end

    def display_verbosity_three(error)
      return unless ActiveMocker::Config.error_verbosity == 3

      display_error_header(error)
      display error.level

      display_original_error(error)
    end

    def display_original_error(e)
      original = e.original_error
      return unless original

      display original.message.colorize(e.level_color)
      display original.backtrace
      display original.class.name.colorize(e.level_color)
    end

    def display_verbosity_two(e)
      return unless ActiveMocker::Config.error_verbosity == 2

      display_error_header(e)
    end

    def display_error_header(e)
      display "#{e.class_name} has the following errors:"
      display e.message.colorize(e.level_color)
    end

    def display_verbosity_one
      return unless ActiveMocker::Config.error_verbosity > 0

      error_summary if any_errors?

      failure_count_message

      return unless any_errors?
      display "To see more/less detail set error_verbosity = 0, 1, 2, 3"
    end

    def error_count
      errors_for(:red)
    end

    def warn
      errors_for(:yellow)
    end

    def info
      errors_for(:default)
    end

    def errors_for(level)
      uniq_errors.count { |e| [level].include? e.level_color }
    end
  end
end
