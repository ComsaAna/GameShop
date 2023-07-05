defmodule Api.Views.UserView do
  use JSONAPI.View

  def fields, do: [:email, :password, :created_at, :updated_at]
  def type, do: "user"
  def relationships, do: []
end
