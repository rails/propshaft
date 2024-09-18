begin
  require "puma"
  require "puma/configuration"
rescue LoadError
end

class Propshaft::PumaConfig
  def initialize
    if defined?(Puma)
      @resolved_config = Puma::Configuration.new.load.final_options
    end
  end

  def multiple_workers?
    return false unless @resolved_config
    @resolved_config[:workers] > 1
  end

  def self.perform_dev_check!
    return true unless new.multiple_workers?

    message = "#" * 80 + "\n"
    message += "# " + " " * 76 + " #\n"
    message += "# " + "WARNING!!".center(76) + " #\n"
    message += "# " + " " * 76 + " #\n"
    message += "# Running multiple Puma workers in development is not supported with Propshaft #\n"
    message += "# " + " " * 76 + " #\n"
    message += "# " + "Make sure WEB_CONCURRENCY is not set or ensure".center(76) + " #\n"
    message += "# " + "workers is not set for development in config/puma.rb.".center(76) + " #\n"
    message += "# " + " " * 76 + " #\n"
    message += "#" * 80 + "\n"

    puts message
    false
  end
end
