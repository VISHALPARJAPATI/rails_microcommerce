# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user with email and password" do
    user = User.new(email: "valid@example.com", password: "password123", password_confirmation: "password123")
    assert user.valid?
  end

  test "invalid without email" do
    user = User.new(email: "", password: "password123", password_confirmation: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "invalid with short password" do
    user = User.new(email: "a@b.com", password: "short", password_confirmation: "short")
    assert_not user.valid?
    assert user.errors[:password].present?
  end

  test "invalid when password confirmation does not match" do
    user = User.new(email: "a@b.com", password: "password123", password_confirmation: "different")
    assert_not user.valid?
    assert_includes user.errors[:password_confirmation], "doesn't match Password"
  end

  test "invalid with duplicate email" do
    User.create!(email: "taken@example.com", password: "password123", password_confirmation: "password123")
    user = User.new(email: "taken@example.com", password: "password123", password_confirmation: "password123")
    assert_not user.valid?
    assert user.errors[:email].present?
  end

  test "jti is set on create" do
    user = User.create!(email: "jti@example.com", password: "password123", password_confirmation: "password123")
    assert user.jti.present?
    assert user.jti.length >= 32
  end

  test "fixture user can authenticate" do
    user = users(:one)
    assert user.valid_password?("password123")
    assert_not user.valid_password?("wrong")
  end
end
