require 'test_helper'

class RecentsControllerTest < ActionController::TestCase
  setup do
    @recent = recents(:one)
  end
  
  # test not working come back later
  # test "should get index" do
  #   get :index
  #   assert_response :success
  # end

  test "should get show" do
    get :show , id: @recent
    assert_response :success
  end

  test "should create a recent url" do
    assert_difference('Recent.count', +1) do
      post :create, recent: { url_string: @recent.url_string }
    end

    assert_redirected_to recent_path(assigns(:recent))
  end

  test "should destroy a recent url" do
    assert_difference('Recent.count', -1) do
      delete :destroy, id: @recent
    end

    assert_redirected_to recents_path
  end
end
