# frozen_string_literal: true

# Publishes events to Kafka when KAFKA_BROKERS is set.
class KafkaProducerService
  TOPIC_ORDER_COMPLETED = "order.completed"

  class << self
    def publish_order_completed(order)
      return unless kafka_available?

      payload = {
        order_id: order.id,
        user_id: order.user_id,
        total_cents: order.total_cents,
        completed_at: order.updated_at.iso8601
      }
      publish(TOPIC_ORDER_COMPLETED, payload)
    end

    def publish(topic, payload)
      return unless kafka_available?

      kafka.producer.produce(payload.to_json, topic: topic)
      kafka.producer.deliver_messages
    rescue StandardError => e
      Rails.logger.warn("Kafka publish failed: #{e.message}")
    end

    def kafka_available?
      Rails.application.config.respond_to?(:kafka) && Rails.application.config.kafka.present?
    end

    private

    def kafka
      Rails.application.config.kafka
    end
  end
end
