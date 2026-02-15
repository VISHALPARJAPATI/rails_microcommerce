# frozen_string_literal: true

require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "valid with name" do
    category = Category.new(name: "Books")
    assert category.valid?
  end

  test "invalid without name" do
    category = Category.new(name: "")
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "invalid with duplicate name" do
    Category.create!(name: "Unique")
    category = Category.new(name: "Unique")
    assert_not category.valid?
    assert_includes category.errors[:name], "has already been taken"
  end

  test "has many products" do
    category = categories(:electronics)
    assert_respond_to category, :products
    assert_includes category.products.map(&:name), "Wireless Earbuds"
  end
end
