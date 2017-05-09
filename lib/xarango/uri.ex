defmodule Xarango.URI do

  defmacro __using__(options) do
    prefix = options[:prefix]
    quote do
      def url(), do: url("", nil, [])
      def url(path), do: url(path, nil, [])
      def url(path, nil), do: url(path, nil, [])
      def url(path, options) when is_list(options), do: url(path, nil, options)
      def url(path, database) when is_map(database), do: url(path, database, [])
      def url(path, database, options) do
        Xarango.URI.path("#{unquote(prefix)}/#{path}", database)
        |> Xarango.Client._url(options)
      end
    end
  end

  def path(path, database\\nil) do
    case database do
      nil -> path(path, Xarango.Database.default)
      %{name: db_name} when db_name != "_system" -> "/_db/#{db_name}/_api/#{path}"
      %{name: db_name} when db_name == "_system" -> "/_api/#{path}"
      _ -> raise Xarango.Error, message: "invalid database for path"
    end
  end

end
