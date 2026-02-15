# frozen_string_literal: true

class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    orders = current_user.orders.order(created_at: :desc)
    render json: { orders: orders.map { |o| order_json(o) } }
  end

  def show
    order = current_user.orders.find(params[:id])
    render json: { order: order_json(order) }
  end

  private

  def order_json(order)
    {
      id: order.id,
      total_cents: order.total_cents,
      total: (order.total_cents / 100.0).round(2),
      status: order.status,
      stripe_session_id: order.stripe_session_id,
      line_items: order.line_items,
      created_at: order.created_at.iso8601,
      updated_at: order.updated_at.iso8601
    }
  end
end
