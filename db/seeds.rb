# Idempotent seeds: safe to run multiple times.
# Creates sample categories and products for development/demo.

return unless Rails.env.development? || ENV["RAILS_SEED_SAMPLE"].present?

electronics = Category.find_or_create_by!(name: "Electronics")
clothing = Category.find_or_create_by!(name: "Clothing")

Product.find_or_create_by!(name: "Wireless Earbuds") do |p|
  p.category = electronics
  p.price = 49.99
  p.description = "Noise-cancelling wireless earbuds."
end

Product.find_or_create_by!(name: "Cotton T-Shirt") do |p|
  p.category = clothing
  p.price = 19.99
  p.description = "Plain cotton t-shirt, multiple colours."
end

Product.find_or_create_by!(name: "USB-C Hub") do |p|
  p.category = electronics
  p.price = 34.50
  p.description = "Multi-port USB-C hub with HDMI."
end
