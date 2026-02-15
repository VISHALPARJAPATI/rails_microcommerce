# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    respond_to :json

    def create
      build_resource(sign_up_params)
      resource.save
      if resource.persisted?
        sign_in(resource, store: false)
        respond_with resource
      else
        respond_with resource
      end
    end

    private

    def respond_with(resource, _opts = {})
      if resource.persisted?
        render json: { user: resource.as_json(only: %i[id email created_at]) }, status: :created
      else
        render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
