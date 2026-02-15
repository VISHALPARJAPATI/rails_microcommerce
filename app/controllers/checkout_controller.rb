# frozen_string_literal: true

class CheckoutController < ApplicationController
  before_action :authenticate_user!, only: [:create]

  def create
    items = normalize_items(checkout_params[:items])
    result = CreateCheckoutSessionService.new(
      user: current_user,
      items: items,
      success_url: checkout_params[:success_url].presence || default_success_url,
      cancel_url: checkout_params[:cancel_url].presence || default_cancel_url
    ).call
    render json: { checkout_url: result[:url], order_id: result[:order_id] }, status: :ok
  rescue CreateCheckoutSessionService::InvalidLineItems => e
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  private

  def normalize_items(items_param)
    return [] if items_param.blank?
    items_param.is_a?(Array) ? items_param : items_param.to_h.values
  end

  def checkout_params
    params.permit(:success_url, :cancel_url, items: [:product_id, :quantity])
  end

  def default_success_url
    ENV["CHECKOUT_SUCCESS_URL"].presence || "http://localhost:3000/checkout/success"
  end

  def default_cancel_url
    ENV["CHECKOUT_CANCEL_URL"].presence || "http://localhost:3000/checkout/cancel"
  end
end
