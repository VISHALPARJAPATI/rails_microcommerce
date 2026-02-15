# frozen_string_literal: true

class MeController < ApplicationController
  before_action :authenticate_user!

  def show
    render json: { user: current_user.as_json(only: %i[id email created_at]) }
  end
end
