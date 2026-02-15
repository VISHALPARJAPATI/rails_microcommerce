# frozen_string_literal: true

require "test_helper"
require "devise/jwt/test_helpers"

class CheckoutTest < ActionDispatch::IntegrationTest
  def json_headers
    { "Content-Type" => "application/json", "Accept" => "application/json" }
  end

  def auth_headers
    Devise::JWT::TestHelpers.auth_headers(json_headers, users(:one))
  end

  test "POST /checkout without auth returns 401" do
    post checkout_path,
      params: { items: [{ product_id: products(:one).id, quantity: 1 }] }.to_json,
      headers: json_headers
    assert_response :unauthorized
  end

  test "POST /checkout with auth creates session and returns checkout_url" do
    session = Struct.new(:id, :url).new("cs_test_456", "https://checkout.stripe.com/pay/cs_test_456")
    stripe_stub_session(session) do
      assert_difference("Order.count", 1) do
        post checkout_path,
          params: { items: [{ product_id: products(:one).id, quantity: 1 }] }.to_json,
          headers: auth_headers
      end
    end
    assert_response :success
    json = response.parsed_body
    assert_equal "https://checkout.stripe.com/pay/cs_test_456", json["checkout_url"]
    assert json["order_id"].present?
  end

  def stripe_stub_session(session)
    orig = Stripe::Checkout::Session.method(:create)
    Stripe::Checkout::Session.define_singleton_method(:create) { |*_args, **_kwargs| session }
    yield
  ensure
    Stripe::Checkout::Session.define_singleton_method(:create) { |*args, **kwargs| orig.call(*args, **kwargs) }
  end

  test "POST /checkout with invalid product returns 422" do
    post checkout_path,
      params: { items: [{ product_id: 99999, quantity: 1 }] }.to_json,
      headers: auth_headers
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert json["errors"].present?
  end

  test "GET /orders requires auth" do
    get orders_path, headers: json_headers
    assert_response :unauthorized
  end

  test "GET /orders with auth returns user orders" do
    get orders_path, headers: auth_headers
    assert_response :success
    json = response.parsed_body
    assert json["orders"].is_a?(Array)
  end

  test "GET /orders/:id with auth returns order" do
    order = orders(:one)
    get order_path(order), headers: auth_headers
    assert_response :success
    json = response.parsed_body
    assert_equal order.id, json["order"]["id"]
    assert_equal order.status, json["order"]["status"]
  end
end
