# frozen_string_literal: true

class ProductsController < ApplicationController
  def index
    result = FetchProductsService.new(index_params).call
    render json: {
      products: result.products.map { |p| product_json(p) },
      meta: {
        total_count: result.total_count,
        total_pages: result.total_pages,
        current_page: result.current_page,
        per_page: result.per_page
      }
    }
  end

  private

  def index_params
    params.permit(:q, :sort, :order, :page, :per_page)
  end

  def product_json(product)
    {
      id: product.id,
      name: product.name,
      price: product.price.to_f,
      description: product.description,
      category_id: product.category_id,
      category_name: product.category.name,
      created_at: product.created_at.iso8601
    }
  end
end
