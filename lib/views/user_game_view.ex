defmodule Api.Views.UserGameView do
  use JSONAPI.View

  def fields, do: [:id, :user_id, :game_id, :created_at, :updated_at]
  def type, do: "user_game"
  def relationships, do: []
end
