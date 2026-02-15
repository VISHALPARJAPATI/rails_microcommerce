# frozen_string_literal: true

require "test_helper"

class CreateCheckoutSessionServiceTest < ActiveSupport::TestCase
  StripeSession = Struct.new(:id, :url, keyword_init: true)

  setup do
    @user = users(:one)
    @product = products(:one)
    @items = [{ "product_id" => @product.id, "quantity" => 2 }]
    @success_url = "https://example.com/success"
    @cancel_url = "https://example.com/cancel"
  end

  test "creates order and returns url and order_id when Stripe succeeds" do
    session = StripeSession.new(id: "cs_test_123", url: "https://checkout.stripe.com/pay/cs_test_123")
    stripe_stub_session(session) do
      result = CreateCheckoutSessionService.new(
        user: @user,
        items: @items,
        success_url: @success_url,
        cancel_url: @cancel_url
      ).call
      assert_equal "https://checkout.stripe.com/pay/cs_test_123", result[:url]
      assert result[:order_id].present?
      order = Order.find(result[:order_id])
      assert_equal @user.id, order.user_id
      assert_equal "pending", order.status
      assert_equal "cs_test_123", order.stripe_session_id
      assert_equal (@product.price * 100 * 2).round, order.total_cents
    end
  end

  def stripe_stub_session(session)
    orig = Stripe::Checkout::Session.method(:create)
    Stripe::Checkout::Session.define_singleton_method(:create) { |*_args, **_kwargs| session }
    yield
  ensure
    Stripe::Checkout::Session.define_singleton_method(:create) { |*args, **kwargs| orig.call(*args, **kwargs) }
  end

  test "raises InvalidLineItems when product not found" do
    assert_raises CreateCheckoutSessionService::InvalidLineItems do
      CreateCheckoutSessionService.new(
        user: @user,
        items: [{ "product_id" => 99999, "quantity" => 1 }],
        success_url: @success_url,
        cancel_url: @cancel_url
      ).call
    end
  end

  test "raises InvalidLineItems when quantity is zero" do
    assert_raises CreateCheckoutSessionService::InvalidLineItems do
      CreateCheckoutSessionService.new(
        user: @user,
        items: [{ "product_id" => @product.id, "quantity" => 0 }],
        success_url: @success_url,
        cancel_url: @cancel_url
      ).call
    end
  end
end
