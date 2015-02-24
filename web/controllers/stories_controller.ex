defmodule News.StoriesController do
	use Phoenix.Controller
	alias Poison, as: JSON
	require Logger
	plug :action

	def index(conn, params) do
		Logger.debug("Params: #{inspect params}")
		%{"count" => s_count, "language" => language} = params
		count = String.to_integer(s_count)
	  stories = News.Hacker.get(count, 0, language)
		json conn, stories
	end

end
