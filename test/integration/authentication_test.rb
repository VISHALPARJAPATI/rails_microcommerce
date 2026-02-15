# frozen_string_literal: true

require "test_helper"
require "devise/jwt/test_helpers"

class AuthenticationTest < ActionDispatch::IntegrationTest
  def json_headers
    { "Content-Type" => "application/json", "Accept" => "application/json" }
  end

  test "sign up with valid params creates user and returns token in header" do
    assert_difference("User.count", 1) do
      post user_registration_url,
        params: { user: { email: "new@example.com", password: "password123", password_confirmation: "password123" } }.to_json,
        headers: json_headers
    end
    assert_response :created
    assert response.headers["Authorization"].present?
    assert_match(/\ABearer /, response.headers["Authorization"])
    json = response.parsed_body
    assert_equal "new@example.com", json["user"]["email"]
    assert json["user"]["id"].present?
  end

  test "sign up with invalid params returns 422 and errors" do
    assert_no_difference("User.count") do
      post user_registration_url,
        params: { user: { email: "", password: "short", password_confirmation: "short" } }.to_json,
        headers: json_headers
    end
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert json["errors"].present?
  end

  test "sign in with valid credentials returns user and token in header" do
    user = users(:one)
    post user_session_url,
      params: { user: { email: user.email, password: "password123" } }.to_json,
      headers: json_headers
    assert_response :success
    assert response.headers["Authorization"].present?
    assert_match(/\ABearer /, response.headers["Authorization"])
    json = response.parsed_body
    assert_equal user.email, json["user"]["email"]
  end

  test "sign in with invalid credentials returns 401" do
    post user_session_url,
      params: { user: { email: "nobody@example.com", password: "wrong" } }.to_json,
      headers: json_headers
    assert_response :unauthorized
  end

  test "sign out revokes token and returns 204" do
    user = users(:one)
    auth_headers = Devise::JWT::TestHelpers.auth_headers(json_headers, user)
    delete destroy_user_session_url, headers: auth_headers
    assert_response :no_content
    # Using the same token again should be unauthorized
    get me_url, headers: auth_headers
    assert_response :unauthorized
  end

  test "GET /me without token returns 401" do
    get me_url, headers: json_headers
    assert_response :unauthorized
  end

  test "GET /me with valid token returns current user" do
    user = users(:one)
    auth_headers = Devise::JWT::TestHelpers.auth_headers(json_headers, user)
    get me_url, headers: auth_headers
    assert_response :success
    json = response.parsed_body
    assert_equal user.id, json["user"]["id"]
    assert_equal user.email, json["user"]["email"]
  end

  test "GET /me with expired or invalid token returns 401" do
    get me_url, headers: json_headers.merge("Authorization" => "Bearer invalid-token")
    assert_response :unauthorized
  end
end
