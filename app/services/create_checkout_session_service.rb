# frozen_string_literal: true

class CreateCheckoutSessionService
  class InvalidLineItems < ArgumentError; end

  def initialize(user:, items:, success_url:, cancel_url:)
    @user = user
    @items = items
    @success_url = success_url
    @cancel_url = cancel_url
  end

  def call
    line_items_data = build_line_items
    total_cents = line_items_data.sum { |item| item[:amount] * item[:quantity] }
    order = Order.create!(user: @user, total_cents: total_cents, status: "pending", line_items: @items)

    session = Stripe::Checkout::Session.create(
      mode: "payment",
      customer_email: @user.email,
      line_items: line_items_data.map { |item| stripe_line_item(item) },
      success_url: @success_url,
      cancel_url: @cancel_url,
      metadata: { order_id: order.id }
    )

    order.update!(stripe_session_id: session.id)
    { url: session.url, order_id: order.id }
  end

  private

  def build_line_items
    product_ids = @items.map { |i| i["product_id"] || i[:product_id] }.compact.uniq
    products = Product.where(id: product_ids).index_by(&:id)

    @items.map do |item|
      product_id = (item["product_id"] || item[:product_id]).to_i
      quantity = (item["quantity"] || item[:quantity] || 1).to_i
      raise InvalidLineItems, "Invalid product_id: #{product_id}" if quantity < 1
      product = products[product_id]
      raise InvalidLineItems, "Product not found: #{product_id}" unless product

      amount = (product.price * 100).round
      { product: product, amount: amount, quantity: quantity, name: product.name }
    end
  end

  def stripe_line_item(item)
    {
      price_data: {
        currency: "usd",
        product_data: { name: item[:name] },
        unit_amount: item[:amount]
      },
      quantity: item[:quantity]
    }
  end
end
