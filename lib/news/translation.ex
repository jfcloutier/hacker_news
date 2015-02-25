defmodule News.Translation do
	@moduledoc """
A translation agency that relies on a network of translators.
"""

	use GenServer
	require Logger

	@name __MODULE__
	@group :translators
  @key_file "google_apis.key"
	@max_tries 3

  ### API

  # Singleton server
	def start_link( ) do
		GenServer.start_link(@name, [], [name: @name])
  end

  # Request a translation. Capture faillures (should be timeouts).
	def translate(text, to) do
		try do
			GenServer.call(@name, {:translate, text, to}, 10_000)
    catch
			kind,error -> 
				Logger.debug("Translation failed: #{inspect kind}, #{inspect error}")
				{:error, "Translation failed"}
    end
  end

  ## Callbacks

  # Starts process group management and create a group for translators (no effect if already started)
  # The state remembers the Google API key (nil at first)
	def init(_) do
		:pg2.start
		:pg2.create(@group)
		{:ok, %{key: nil}}
  end

  # Process translation request asynchronously (don't block other incoming requests)
	def handle_call({:translate, text, to}, caller, state) do
		{:ok, key} = get_key(state) # Get the Google API key if needed
		try do
			spawn_link( fn ->
										result = request_translation(text, to, key)
										GenServer.reply(caller, result) # when done, explicitly reply with the result
									end )
			{:noreply, %{state|key: key}} # don't reply now (we're async) but update the state
    catch # capture abnormal exit of spawned process
			kind,error -> 
					Logger.debug("Translation failed: #{inspect kind}, #{inspect error}")
					GenServer.reply(caller, {:error, "Translation failed"})
    end
  end

  ### PRIVATE

  # Find a translator and ask it for a translation
	defp request_translation(text, to, key) do
		result = find_available_translator()
		case result do
			{:ok, pid} ->
				GenServer.call(pid, {:translate, text, to, key}, 10_000)
		  {:error, message} ->
				Logger.error(message)
				{:error, message}
    end
  end

  # Select randomly a translator node
  defp find_available_translator() do
		translators = :pg2.get_members(@group)
		case Enum.count(translators) do
			0 -> {:error, "No translator available"}
			n -> :random.seed(:erlang.now)
					 pid = Enum.at(translators, :random.uniform(n) - 1)
           {:ok, pid}
    end
  end

  #Get the Google API key from file, if not already cached in the state
  defp get_key(%{key: nil} = state) do
		Logger.debug("Retrieving API key from file")
		File.read(@key_file)
  end
	defp get_key(%{key: key} = state) do
		{:ok, key}
  end

end
