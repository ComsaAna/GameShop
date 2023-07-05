defmodule BackendStuffApi.Api.Models.Base do

  alias BackendStuffApi.Api.Helpers.MapHelper

  use Timex

  defmacro __using__(_) do
    quote do

      def get(id) do
        case Mongo.find_one(:mongo, @db_table, %{id: id}) do
          nil ->
            :error
          doc ->
            {:ok, doc |> MapHelper.string_keys_to_atoms |> merge_to_struct}
        end
      end


      def save(document) when is_map(document) do
        document = case {document.created_at, document.updated_at}  do
          {nil, nil} ->
            document
            |> Map.put(:created_at, Timex.to_unix(Timex.now))
            |> Map.put(:updated_at, Timex.to_unix(Timex.now))
          {_, _} ->
            document
            |> Map.put(:updated_at, Timex.to_unix(Timex.now))
        end
        |> Map.from_struct

        # Saving document
        case Mongo.insert_one(:mongo, @db_table, document) do
          {:ok, _} ->
            {:ok, document}
          _ ->
            :error
        end
      end


      # def find(filters) when is_map(filters) do
      # end


      def delete(id) do
        # Deleting document
        {:ok, rows} = Mongo.delete_one(:mongo, @db_table, %{id: id})
        cond do
          rows.deleted_count == 0 ->
            :error

          rows.deleted_count > 0 ->
            :ok
        end
      end


      defp merge_to_struct(document) when is_map(document) do
         __struct__ |> Map.merge(document)
      end
    end
  end
end
