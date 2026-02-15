# frozen_string_literal: true

class ProductsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update]
  before_action :set_product, only: [:update]

  def index
    payload = ProductsCache.fetch(index_params) do
      result = FetchProductsService.new(index_params).call
      {
        products: result.products.map { |p| product_json(p) },
        meta: {
          total_count: result.total_count,
          total_pages: result.total_pages,
          current_page: result.current_page,
          per_page: result.per_page
        }
      }
    end
    render json: payload
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      ProductsCache.invalidate!
      render json: { product: product_json(@product) }, status: :created
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      ProductsCache.invalidate!
      render json: { product: product_json(@product) }
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def index_params
    params.permit(:q, :category_id, :sort, :order, :page, :per_page)
  end

  def product_params
    params.require(:product).permit(:name, :price, :description, :category_id)
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
