# frozen_string_literal: true

class StripeWebhookController < ApplicationController
  # No authentication; Stripe signature verification only (API-only app has no CSRF)
  before_action :verify_stripe_signature

  def create
    case @event.type
    when "checkout.session.completed"
      handle_checkout_completed(@event.data.object)
    end
    head :ok
  end

  private

  def verify_stripe_signature
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    secret = ENV["STRIPE_WEBHOOK_SECRET"].presence || Rails.application.credentials.dig(:stripe_webhook_secret)
    return head :bad_request if secret.blank?
    @event = Stripe::Webhook.construct_event(payload, sig_header, secret)
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.warn("Stripe webhook error: #{e.message}")
    head :bad_request
  end

  def handle_checkout_completed(session)
    order = Order.find_by(stripe_session_id: session.id)
    order&.update!(status: "completed")
  end
end
