require "test_helper"

class PropshaftIntegrationTest < ActionDispatch::IntegrationTest
  test "should be able to resolve real assets" do
    get sample_load_real_assets_url
    assert_response :success
    assert_select 'link[href="/assets/hello_world-ee414c137ef3c7b9125cd90168875cb61938bc52.css"]'
    assert_select 'script[src="/assets/hello_world-00956908343eaa8d47963b94a7e47ae2919a79cd.js"]'
  end

  test "should raise an exception when resolving nonexistent assets" do
    exception = assert_raises ActionView::Template::Error do
      get sample_load_nonexistent_assets_url
    end
    assert_equal "The asset 'nonexistent.css' was not found in the load path.", exception.message
  end

  test "should be able to resolve javascript assets with integrity" do
    get sample_load_assets_with_integrity_url
    assert_response :success
    assert_select 'script[src="/assets/hello_world-00956908343eaa8d47963b94a7e47ae2919a79cd.js"][integrity="sha384-BIr0kyMRq2sfytK/T0XlGjfav9ZZrWkSBC2yHVunCchnkpP83H28/UtHw+m9iNHO"]'
  end
end
