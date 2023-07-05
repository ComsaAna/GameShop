defmodule Api.Views.GameView do
  use JSONAPI.View

  def fields, do: [:name, :year, :created_at, :updated_at]
  def type, do: "game"
  def relationships, do: []
end
