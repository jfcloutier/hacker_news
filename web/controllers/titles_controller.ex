defmodule News.TitlesController do
	use Phoenix.Controller
	alias Poison, as: JSON
	require Logger
	plug :action

	def index(conn, params) do
		Logger.debug("Params: #{inspect params}")
		%{"count" => s_count, "language" => language} = params
		count = String.to_integer(s_count)
	  titles = News.Hacker.get(count, 0, "title", language)
		array = Enum.map(titles,fn(title)->%{title: title} end)
		json conn, array
	end

end
