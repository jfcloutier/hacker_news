defmodule News.Hacker do
	@moduledoc """
An agent responsible for retrieving top stories from Hacker News
"""

	require Logger

	@name __MODULE__

	#### API

	def start_link() do
	  Logger.debug( "Starting Hacker News Service" )
		{:ok, _pid} = Agent.start_link(fn -> fetch_top_story_ids() end, [name: @name, timeout: 20_000])
	end
	
  # Languages reference: https://cloud.google.com/translate/v2/using_rest#language-params
	def get(count, index, language \\ nil) do
		stories = collect(count, index)
		if language == nil or language == "en" do
			stories
		else
			stories
			|> map_reduce(fn(story) -> 
										 {story, News.Translation.translate(story["title"], language)} 
									 end)
			|> Enum.map(fn({story, {_,translation}} = response) -> %{story|"title" => translation} end)
		end
	end

	#### PRIVATE

	defp get_stories do
		Agent.get(@name, &(&1))
	end

	defp fetch_top_story_ids do
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
				if cached_story == nil or cached_story["id"] == -1 do
          try do
						Logger.debug("Fetching story #{id}")
						story = ExFirebase.get("item/#{id}")
						{story, Dict.put(stories, id, story)}
          catch
						error -> Logger.debug("Failed to retrieve story: #{inspect error}")
							       story = %{"id" => -1, "url" => "", "title" => "Failed to retrieve story", "score" => 0}
										 {story, Dict.put(stories, id, story)}
				  end
				else 
				{cached_story, stories}
				end
			end,
			:infinity
		)
	end

	defp collect(count, index) do 
		try do
      get_stories()
			|> Enum.drop(index)
			|> Enum.take(count)
		  |> Enum.map(fn({story_id, _story}) -> story_id end)
      |> Enum.to_list
		  |> map_reduce(fn(story_id) -> fetch(story_id) end)
    rescue
			_ -> Logger.error("Failed to collect stories"); []
    end
	end

  def map_reduce(collection, function) do
    me = self
    collection
    |> Enum.map(fn(elem) -> 
									spawn_link(fn -> 
														 (send me, { self, function.(elem) }) 
														 end) 
								end) 
    |> Enum.map(fn(pid) ->  
									receive do { ^pid, result } -> result end 
								end)
  end

end
