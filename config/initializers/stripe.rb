# frozen_string_literal: true

Stripe.api_key = ENV["STRIPE_SECRET_KEY"].presence || Rails.application.credentials.dig(:stripe_secret_key)
