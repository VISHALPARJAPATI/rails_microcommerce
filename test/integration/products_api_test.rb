# frozen_string_literal: true

require "test_helper"

class ProductsApiTest < ActionDispatch::IntegrationTest
  def get_products(params = {})
    get products_path, params: params, headers: { "Accept" => "application/json" }
  end

  test "GET /products returns paginated products with meta" do
    get_products
    assert_response :success
    json = response.parsed_body
    assert json["products"].is_a?(Array)
    assert json["meta"].present?
    assert_equal Product.count, json["meta"]["total_count"]
    assert json["meta"]["current_page"].present?
    assert json["meta"]["total_pages"].present?
    assert json["meta"]["per_page"].present?
    assert json["products"].first["name"].present? if json["products"].any?
    assert json["products"].first["price"].present? if json["products"].any?
    assert json["products"].first["category_name"].present? if json["products"].any?
  end

  test "GET /products with q searches" do
    get_products(q: "Wireless")
    assert_response :success
    json = response.parsed_body
    assert_equal 1, json["meta"]["total_count"]
    assert_equal "Wireless Earbuds", json["products"].first["name"]
  end

  test "GET /products with sort and order" do
    get_products(sort: "name", order: "asc")
    assert_response :success
    json = response.parsed_body
    names = json["products"].map { |p| p["name"] }
    assert_equal names.sort, names
  end

  test "GET /products with pagination" do
    get_products(page: 1, per_page: 1)
    assert_response :success
    json = response.parsed_body
    assert_equal 1, json["products"].size
    assert_equal Product.count, json["meta"]["total_count"]
    assert_equal (Product.count.to_f / 1).ceil, json["meta"]["total_pages"]
  end
end
