require "test_helper"

class PropshaftIntegrationTest < ActionDispatch::IntegrationTest
  test "should be able to resolve real assets" do
    get sample_load_real_assets_url

    assert_response :success

    assert_select 'link[href="/assets/hello_world-4137140a.css"]'
    assert_select 'link[href="/assets/goodbye-b1dc9940.css"]'

    assert_select 'script[src="/assets/hello_world-888761f8.js"]'
  end

  test "should raise an exception when resolving nonexistent assets" do
    exception = assert_raises ActionView::Template::Error do
      get sample_load_nonexistent_assets_url
    end
    assert_equal "The asset 'nonexistent.css' was not found in the load path.", exception.message
  end
end
