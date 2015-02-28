defmodule News.Desk do
	@moduledoc """
An agent responsible for retrieving top stories from Hacker News via Firebase 
and for farming out the translation of the story titles to a group of translator nodes.
"""

	require Logger
  use Timex

	@name __MODULE__
  @shelf_life 10 # Stories are refreshed every 10 minutes
	@failed -1 # Story id indicating failure to retrieve story content

	#### API

  # The initial state of the Agent is a dictionary of story_id => story_as_map (story is nil at first)
  # with the time their ids were first retrieved
	# The state retains the ids of all top stories and acts as a cache of retrieved stories.
	def start_link() do
	  Logger.debug( "Starting Hacker News Service" )
		{:ok, _pid} = Agent.start_link(
			fn -> {Time.now, fetch_top_story_ids()} end, 
			[name: @name, timeout: 20_000])
	end

  # Get a list of the top 'count' stories and translate their titles, if given a language code	
	def get(count, language \\ nil) do
		stories = collect(count) # get the stories, making sure their content was retrieved
		if language == nil or language == "en" do # Don't translate
			stories
		else
			stories
			|> map_reduce(fn(story) -> # Delegate to the network of translators (in parallel)
					{story, News.Translation.translate(story["title"], language)} 
										end)
			|> Enum.map( # Replace the original story titles with their translations
					fn
						{story, {_,translation}} when is_map(story) -> %{story|"title" => translation}
						response -> Logger.debug("Translation failed: #{inspect response}")
												failed_story()
          end
				)
		end
	end

	#### PRIVATE

	# Return the stories cached in the state of the Agent, refreshed if stale 
	defp get_stories do
		Agent.get_and_update(@name, 
												 fn({time, stories}) ->
													 if Time.elapsed(time, :mins) > @shelf_life do
														 fresh_stories = fetch_top_story_ids
														 {fresh_stories, {Time.now, fetch_top_story_ids()}}
													 else
														 {stories, {time,stories}}
													 end
												 end)
	end

  # Fetch via Firebase the ids of Hacker News' top stories.
  # Return a dictionary keyed by story id and with nil (story not yet retrieved) as values
	defp fetch_top_story_ids do
		ExFirebase.set_url("https://hacker-news.firebaseio.com/v0/")
		top_ids = ExFirebase.get( "topstories" )
		Logger.debug( "Top story ids: \n#{inspect top_ids}" )
		Enum.reduce(top_ids, 
								HashDict.new,
			fn(id, dict) -> Dict.put(dict, id, nil) end
		)
	end

	# Return the top 'count' stories, making sure the contents of each one has been fetched
	defp collect(count) do 
    get_stories() # all current top stories, some or all of which may not have been retrieved yet
		|> Enum.take(count)
		|> Enum.map(fn({story_id, _story}) -> story_id end)
		|> map_reduce(fn(story_id) -> fetch(story_id) end) # fetch the content of stories in parallel
	end

	# Get a story by id, fetching its content if not already done. 
  # Update the cache of stories (the state of the Agent)
	defp fetch(id) do
		Agent.get_and_update(
			@name,
			fn({time,stories}) ->
				cached_story = Dict.get(stories, id, nil)
				if cached_story == nil or cached_story["id"] == @failed do
          try do
						Logger.debug("Fetching story #{id}")
						story = ExFirebase.get("item/#{id}")
						{story, {time, Dict.put(stories, id, story)}} # return story and updated Agent state
          catch
						kind,error -> Logger.debug("Failed to retrieve story: #{inspect kind} , #{inspect error}")
													story = failed_story()
													{story, {time, Dict.put(stories, id, story)}}
				  end
				else 
				{cached_story, {time, stories}} # return cached story and unmodified Agent state
				end
			end,
			:infinity
		)
	end

	# Story after a failed attempt are retrieving its content
	defp failed_story do
		%{"id" => @failed, "url" => "", "title" => "Failed to retrieve story", "score" => 0}
  end

  # Parallel mapping of a function on a collection. Results are collected in same order.
  defp map_reduce(collection, function) do
    me = self
    collection
    |> Enum.map(fn(elem) -> 
									spawn_link(fn -> 
														 (send me, { self, function.(elem) }) 
														 end) 
								end) 
    |> Enum.map(fn(pid) ->  
									receive do { ^pid, result } -> # ^pid enforces retrieval in order from mailbox
											result 
									end 
								end)
  end

end
