# frozen_string_literal: true

# Versioned cache for the products list. Uses Rails.cache (Redis if REDIS_URL is set).
# Call invalidate! after creating or updating a product.
module ProductsCache
  CACHE_VERSION_KEY = "products/cache_version"
  CACHE_KEY_PREFIX = "products/list"
  DEFAULT_EXPIRES_IN = 5.minutes

  class << self
    def fetch(params, expires_in: DEFAULT_EXPIRES_IN)
      key = cache_key(params)
      Rails.cache.fetch(key, expires_in: expires_in) { yield }
    end

    def invalidate!
      version = (Rails.cache.read(CACHE_VERSION_KEY) || 0).to_i
      Rails.cache.write(CACHE_VERSION_KEY, version + 1)
    end

    def cache_key(params)
      normalized = params.to_h.with_indifferent_access.slice(
        :q, :category_id, :sort, :order, :page, :per_page
      ).sort.to_param
      digest = Digest::SHA256.hexdigest(normalized)
      version = (Rails.cache.read(CACHE_VERSION_KEY) || 0).to_i
      "#{CACHE_KEY_PREFIX}/#{version}/#{digest}"
    end
  end
end
