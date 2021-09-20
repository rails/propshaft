require "test_helper"

class Propshaft::DigestUtilTest < ActiveSupport::TestCase
  def setup
    @test_obj = Object.new
    @test_obj.extend(Propshaft::DigestUtils)
  end

  test "digest is removed if any" do
    assert_equal "application.js",  @test_obj.without_digest("application.js")
    assert_equal "application.js",  @test_obj.without_digest("application-f2e1ec14d6856e1958083094170ca6119c529a73.js")
  end
end
