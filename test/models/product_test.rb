# frozen_string_literal: true

require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "valid with name, price, and category" do
    product = Product.new(name: "Widget", price: 10.50, category: categories(:electronics))
    assert product.valid?
  end

  test "invalid without name" do
    product = Product.new(name: "", price: 10, category: categories(:electronics))
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "invalid without price" do
    product = Product.new(name: "Widget", price: nil, category: categories(:electronics))
    assert_not product.valid?
    assert_includes product.errors[:price], "can't be blank"
  end

  test "invalid with negative price" do
    product = Product.new(name: "Widget", price: -1, category: categories(:electronics))
    assert_not product.valid?
    assert product.errors[:price].present?
  end

  test "belongs to category" do
    product = products(:one)
    assert_equal product.category.name, "Electronics"
  end
end
