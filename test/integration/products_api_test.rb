# frozen_string_literal: true

require "test_helper"
require "devise/jwt/test_helpers"

class ProductsApiTest < ActionDispatch::IntegrationTest
  def json_headers
    { "Content-Type" => "application/json", "Accept" => "application/json" }
  end

  def auth_headers
    Devise::JWT::TestHelpers.auth_headers(json_headers, users(:one))
  end

  def get_products(params = {})
    get products_path, params: params, headers: json_headers
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

  test "POST /products without auth returns 401" do
    assert_no_difference("Product.count") do
      post products_path, params: { product: { name: "New", price: 10, category_id: categories(:electronics).id } }.to_json, headers: json_headers
    end
    assert_response :unauthorized
  end

  test "POST /products with auth creates product and returns 201" do
    assert_difference("Product.count", 1) do
      post products_path,
        params: { product: { name: "New Product", price: 29.99, description: "A new item", category_id: categories(:electronics).id } }.to_json,
        headers: auth_headers
    end
    assert_response :created
    json = response.parsed_body
    assert_equal "New Product", json["product"]["name"]
    assert_equal 29.99, json["product"]["price"].to_f
    assert_equal "A new item", json["product"]["description"]
    assert_equal categories(:electronics).id, json["product"]["category_id"]
    assert json["product"]["id"].present?
  end

  test "POST /products with invalid params returns 422" do
    assert_no_difference("Product.count") do
      post products_path,
        params: { product: { name: "", price: -1, category_id: categories(:electronics).id } }.to_json,
        headers: auth_headers
    end
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert json["errors"].present?
  end

  test "PATCH /products/:id without auth returns 401" do
    product = products(:one)
    patch product_path(product), params: { product: { name: "Updated" } }.to_json, headers: json_headers
    assert_response :unauthorized
    assert_equal "Wireless Earbuds", product.reload.name
  end

  test "PATCH /products/:id with auth updates product and returns 200" do
    product = products(:one)
    patch product_path(product),
      params: { product: { name: "Updated Earbuds", price: 59.99, description: "Updated desc" } }.to_json,
      headers: auth_headers
    assert_response :success
    product.reload
    assert_equal "Updated Earbuds", product.name
    assert_equal 59.99, product.price.to_f
    assert_equal "Updated desc", product.description
    json = response.parsed_body
    assert_equal "Updated Earbuds", json["product"]["name"]
  end

  test "PATCH /products/:id with invalid params returns 422" do
    product = products(:one)
    patch product_path(product),
      params: { product: { name: "", price: -5 } }.to_json,
      headers: auth_headers
    assert_response :unprocessable_entity
    assert_equal "Wireless Earbuds", product.reload.name
    json = response.parsed_body
    assert json["errors"].present?
  end

  test "PATCH /products/:id with invalid id returns 404" do
    patch product_path(id: 99999), params: { product: { name: "X" } }.to_json, headers: auth_headers
    assert_response :not_found
  end
end
