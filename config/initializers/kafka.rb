# frozen_string_literal: true

# Optional Kafka client for Step 8 API optimization.
# Set KAFKA_BROKERS (e.g. "localhost:9092") to enable.
Rails.application.config.after_initialize do
  brokers = ENV["KAFKA_BROKERS"].to_s.strip
  if brokers.present?
    Rails.application.config.kafka = Kafka.new(
      brokers.split(",").map(&:strip),
      client_id: ENV.fetch("KAFKA_CLIENT_ID", "rails_microcommerce")
    )
  else
    Rails.application.config.kafka = nil
  end
rescue LoadError, StandardError => e
  Rails.logger.warn("Kafka not configured or unavailable: #{e.message}")
  Rails.application.config.kafka = nil
end
