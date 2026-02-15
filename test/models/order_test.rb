# frozen_string_literal: true

require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "belongs to user" do
    order = orders(:one)
    assert_equal users(:one), order.user
  end

  test "valid with required attributes" do
    order = Order.new(user: users(:one), total_cents: 1000, status: "pending")
    assert order.valid?
  end

  test "invalid without total_cents" do
    order = Order.new(user: users(:one), status: "pending")
    assert_not order.valid?
    assert_includes order.errors[:total_cents], "can't be blank"
  end

  test "status must be valid" do
    order = Order.new(user: users(:one), total_cents: 1000, status: "invalid")
    assert_not order.valid?
    assert order.errors[:status].present?
  end
end
