defmodule News.TranslationBureau do
	@moduledoc """
A translation bureau that relies on a network of translators.
"""

	use GenServer

	require Logger

	@name __MODULE__
	@group :translator
  @key_file "google_apis.key"

	def start_link( ) do
		GenServer.start_link(@name, [], [name: @name])
  end

	def init(_) do
		:pg2.start
		:pg2.create(@group)
		:pg2.join(@group, self)
		{:ok, %{key: nil}}
  end

	def translate(text, to) do
		GenServer.call(@name, {:translate, text, to})
  end

	def handle_call({:translate, text, to}, caller, state) do
		{:ok, key} = get_key(state)
		spawn( fn ->
						 result = request_translation(text, to, key)
						 GenServer.reply(caller, result)
					 end )
		{:noreply, %{state|key: key}}
  end


	defp request_translation(text, to, key) do
		result = find_available_translator()
		case result do
			{:ok, pid} ->
				GenServer.call(pid, {:translate, text, to, key})
		  {:error, message} ->
				Logger.error(message)
				{:error, message}
    end
  end

  defp find_available_translator() do
		translators = :pg2.get_members(@group) |> Enum.filter(fn(pid) -> pid != self end)
		case Enum.count(translators) do
			0 -> {:error, "No translator available"}
			n -> pid = Enum.at(translators, :random.uniform(n) - 1)
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