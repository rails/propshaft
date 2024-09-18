require "test_helper"
require "puma"
require "propshaft/puma_config"
require "minitest/mock"

class Propshaft::PumaConfigTest < ActiveSupport::TestCase
  class PumaConfigurationStub
    def initialize(workers)
      @workers = workers
    end

    def load
      OpenStruct.new(final_options: { workers: @workers })
    end
  end

  {
    0 => false,
    1 => false,
    2 => true
  }.each_pair do |workers, expected|
    test "multiple_workers? is #{expected} when config resolves to #{workers}" do
      mock = PumaConfigurationStub.new(workers)
      Puma::Configuration.stub :new, mock do
        assert Propshaft::PumaConfig.new.multiple_workers? == expected
      end
    end
  end
end
