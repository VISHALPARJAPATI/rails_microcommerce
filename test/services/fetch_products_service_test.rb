# frozen_string_literal: true

require "test_helper"

class FetchProductsServiceTest < ActiveSupport::TestCase
  setup do
    @electronics = categories(:electronics)
    @clothing = categories(:clothing)
    @earbuds = products(:one)
    @tshirt = products(:two)
  end

  test "returns all products with default pagination" do
    result = FetchProductsService.new({}).call
    assert_equal 1, result.current_page
    assert_equal FetchProductsService::DEFAULT_PER_PAGE, result.per_page
    assert result.total_count >= 1
    assert result.products.size >= 1
    assert_equal (result.total_count.to_f / result.per_page).ceil, result.total_pages
  end

  test "search filters by name" do
    result = FetchProductsService.new(q: "Wireless").call
    assert_equal 1, result.total_count
    assert_equal "Wireless Earbuds", result.products.first.name
  end

  test "search filters by description" do
    result = FetchProductsService.new(q: "cotton").call
    assert_equal 1, result.total_count
    assert_equal "Cotton T-Shirt", result.products.first.name
  end

  test "search returns empty when no match" do
    result = FetchProductsService.new(q: "nonexistent").call
    assert_equal 0, result.total_count
    assert result.products.empty?
  end

  test "sort by name ascending" do
    result = FetchProductsService.new(sort: "name", order: "asc").call
    names = result.products.pluck(:name)
    assert_equal names, names.sort
  end

  test "sort by name descending" do
    result = FetchProductsService.new(sort: "name", order: "desc").call
    names = result.products.pluck(:name)
    assert_equal names, names.sort.reverse
  end

  test "sort by price ascending" do
    result = FetchProductsService.new(sort: "price", order: "asc").call
    prices = result.products.pluck(:price)
    assert_equal prices, prices.sort
  end

  test "pagination limits results" do
    result = FetchProductsService.new(page: 1, per_page: 1).call
    assert_equal 2, result.total_count
    assert_equal 1, result.products.size
    assert_equal 2, result.total_pages
    assert_equal 1, result.current_page
  end

  test "pagination second page" do
    result = FetchProductsService.new(page: 2, per_page: 1).call
    assert_equal 1, result.products.size
    assert_equal 2, result.current_page
  end

  test "invalid sort column falls back to default" do
    result = FetchProductsService.new({ sort: "invalid_column" }).call
    assert_equal Product.count, result.total_count
    assert result.products.size >= 1
  end

  test "per_page capped at max" do
    result = FetchProductsService.new(per_page: 999).call
    assert_equal FetchProductsService::MAX_PER_PAGE, result.per_page
  end
end
