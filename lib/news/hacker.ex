defmodule News.Hacker do
	@moduledoc """
An agent responsible for retrieving top stories from Hacker News
"""

	require Logger

	@name __MODULE__

	#### API

	def start_link() do
	  Logger.debug( "Starting Hacker News Service" )
		{:ok, _pid} = Agent.start_link(fn -> fetch_top_stories() end, [name: @name, timeout: 10_000])
	end
 
  # Langueg reference: https://cloud.google.com/translate/v2/using_rest#language-params
	def get(count, index, prop, language \\ nil) do
		items = collect(index, count, prop)
		if language == nil do
			items
		else
			items
			|> Enum.map(fn(story) -> 
										News.Translation.translate(story, language) 
									end)
			|> Enum.map(fn({_, translation} = response) -> translation end)
		end
	end

	#### PRIVATE

	defp get_stories do
		Agent.get(@name, &(&1))
	end

	defp fetch_top_stories do
		ExFirebase.set_url("https://hacker-news.firebaseio.com/v0/")
		top_ids = ExFirebase.get( "topstories" )
		Logger.debug( "#{inspect top_ids}" )
		Enum.reduce(top_ids, 
								HashDict.new,
			fn(id, dict) -> Dict.put(dict, id, nil) end
		)
	end

	defp fetch(id) do
		Agent.get_and_update(
			@name,
			fn(stories) ->
				cached_story = Dict.get(stories, id, nil)
				if cached_story == nil do
					story = ExFirebase.get("item/#{id}")
					{story, Dict.put(stories, id, story)}
				else 
				{cached_story, stories}
				end
			end
		)
	end

	defp collect(index, count, prop) do 
		true = prop in ["id", "by", "type", "title", "url", "text", "kids", "score", "parent", "time"]
		try do
			Stream.drop(get_stories(), index)
			|> Stream.take(count)
		  |> Stream.map(fn({story_id, _story}) -> story_id end)
		  |> Stream.map(fn(story_id) -> fetch(story_id)[prop] end)
      |> Enum.map(&(&1))
    rescue
			_ -> Logger.error("Access to HN on Firebase failed"); []
    end
	end

end
