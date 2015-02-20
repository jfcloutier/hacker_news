defmodule News.TranslationBureau do
	@moduledoc """
A translation bureau that relies on a network of translators.
"""

	use GenServer

	require Logger

	@name __MODULE__
	@group :translator

	def start_link( ) do
		GenServer.start_link(@name, [], [name: @name])
  end

	def init(_) do
		:pg2.start
		:pg2.create(@group)
		:pg2.join(@group, self)
		{:ok, []}
  end

	def translate(text, from, to) do
		GenServer.call(@name, {:translate, text, from, to})
  end

	def handle_call({:translate, text, from, to}, caller, state) do
		spawn( fn ->
						 result = request_translation(text, from, to)
						 GenServer.reply(caller, result)
					 end )
		{:noreply, state}
  end

	defp request_translation(text, from, to) do
		result = find_available_translator()
		case result do
			{:ok, pid} ->
				{:ok, translation} = GenServer.call(pid, {:translate, text, from, to})
				{:translation, translation, pid}
		  {:error, message} ->
				Logger.error(message)
				{:error, message}
    end
  end

  def find_available_translator() do
		translators = :pg2.get_members(@group) 
    |> Enum.filter(fn(pid) -> pid != self end)
		case Enum.count(translators) do
			 0 -> {:error, "No translator available"}
			 n -> pid = Enum.at(translators, :random.uniform(n) - 1)
            {:ok, pid}
    end
  end

end
