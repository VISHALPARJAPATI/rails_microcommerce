# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Expose Authorization so clients can send/receive JWT.
# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*" # Restrict in production, e.g. origins "https://your-frontend.com"
    resource "*",
      headers: %w[Authorization Content-Type Accept],
      methods: %i[get post put patch delete options head],
      expose: %w[Authorization]
  end
end
