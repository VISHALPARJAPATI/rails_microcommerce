# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    respond_to :json

    def create
      self.resource = warden.authenticate!(auth_options)
      sign_in(resource, store: false)
      respond_with resource
    end

    private

    def respond_with(resource, _opts = {})
      render json: { user: resource.as_json(only: %i[id email created_at]) }, status: :ok
    end

    def respond_to_on_destroy(*)
      head :no_content
    end
  end
end
