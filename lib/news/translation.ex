defmodule News.Translation do
	@moduledoc """
A translation bureau that relies on a network of translators.
"""

	use GenServer

	require Logger

	@name __MODULE__
	@group :translators
  @key_file "google_apis.key"
	@max_tries 3

	def start_link( ) do
		GenServer.start_link(@name, [], [name: @name])
  end

	def init(_) do
		:pg2.start
		:pg2.create(@group)
		{:ok, %{key: nil}}
  end

	def translate(text, to) do
		try do
			GenServer.call(@name, {:translate, text, to}, 10_000)
    catch
			kind,error -> 
				Logger.debug("Translation failed: #{inspect kind}, #{inspect error}")
				{:error, "Translation failed"}
    end
  end

	def handle_call({:translate, text, to}, caller, state) do
		{:ok, key} = get_key(state)
		try do
			spawn_link( fn ->
										result = request_translation(text, to, key)
										GenServer.reply(caller, result)
									end )
			{:noreply, %{state|key: key}}
    catch 
			kind,error -> 
					Logger.debug("Translation failed: #{inspect kind}, #{inspect error}")
					GenServer.reply(caller, {:error, "Translation failed"})
    end
  end

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

  defp find_available_translator() do
		translators = :pg2.get_members(@group)
		case Enum.count(translators) do
			0 -> {:error, "No translator available"}
			n -> :random.seed(:erlang.now)
					 pid = Enum.at(translators, :random.uniform(n) - 1)
           {:ok, pid}
    end
  end

  defp get_key(%{key: nil} = state) do
		Logger.debug("Retrieving API key from file")
		File.read(@key_file)
  end
	defp get_key(%{key: key} = state) do
		{:ok, key}
  end

end
