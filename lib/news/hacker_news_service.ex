defmodule News.HackerNewsService do
	@moduledoc """
An agent responsible for retrieving top stories from Hacker News
"""

	require Logger

	@name __MODULE__

	#### API

	def start_link() do
	  Logger.debug( "Starting Hacker News Service" )
		{:ok, _pid} = Agent.start_link(fn -> fetch_top_stories() end, [name: @name])
	end

	# 
	def get(from, count, prop \\ nil) do 
		true = (prop == nil || prop in ["id", "by", "type", "title", "url", "text", "kids", "score", "parent", "time"])
		try do
			Stream.drop(get_stories, from)
			|> Stream.take(count)
		  |> Stream.map(fn({story_id, _story}) -> story_id end)
		  |> Stream.map(fn(story_id) -> 
											if prop !== nil  do 
											    fetch(story_id)[prop] 
											else 
											    fetch(story_id)
											end 
										end)
      |> Enum.map(&(&1))
    rescue
	   _ -> Logger.error("Access to HN on Firebase failed"); []
    end
end

def stories_count do
	Enum.count( get_stories )
end

#### PRIVATE

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

defp get_stories do
	Agent.get(@name, &(&1))
end

end
