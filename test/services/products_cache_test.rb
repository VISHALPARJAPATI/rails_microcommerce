# frozen_string_literal: true

require "test_helper"

class ProductsCacheTest < ActiveSupport::TestCase
  test "fetch returns block result" do
    params = { page: 1, per_page: 10 }
    result = ProductsCache.fetch(params) { { data: "cached" } }
    assert_equal({ data: "cached" }, result)
  end

  test "cache_key is deterministic for same params" do
    params = { q: "x", page: 1 }
    key1 = ProductsCache.cache_key(params)
    key2 = ProductsCache.cache_key(params.with_indifferent_access)
    assert_equal key1, key2
  end

  test "invalidate! does not raise" do
    assert_nothing_raised { ProductsCache.invalidate! }
  end
end
