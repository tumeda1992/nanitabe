class ExecutionTimer
  def initialize(execution_name: nil)
    @execution_name = execution_name
    @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @before_phase_time = @start_time

    if execution_name.present?
      Rails.logger.info "★Started(#{current_time_string}): #{@execution_name}"
    end
  end

  def log_elapsed_time(phase_name: nil)
    current_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed_from_start = current_time - @start_time
    elapsed_from_last_phase = current_time - @before_phase_time
    @before_phase_time = current_time

    log_message = "★Elapsed(#{current_time_string}): #{elapsed_from_start.round(3)} sec"
    log_message += " (#{elapsed_from_last_phase.round(3)} sec since last phase)"
    log_message += " - #{@execution_name}" if @execution_name.present?
    log_message += " - #{phase_name}" if phase_name.present?

    Rails.logger.info log_message
  end

  private

  def current_time_string
    Time.current.strftime("%H:%M:%S.%L")
  end
end
