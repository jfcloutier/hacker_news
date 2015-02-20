defmodule News.ServiceSupervisor do
	@moduledoc """
News' top supervisor.
It is itself supervised by the Phoenix supervisor.
"""
	@name __MODULE__
	use Supervisor
	require Logger

	### Supervisor Callbacks

	@spec start_link() :: {:ok, pid}
  def start_link() do
		Logger.debug "Starting service supervisor"
		{:ok, _pid} = Supervisor.start_link(@name, [], [name: @name])
	end 

	@spec init(any) :: {:ok, tuple}
	def init(_) do
		children = [	
								 worker(News.HackerNewsService, []),
								 worker(News.TranslationBureau, [])
					   ]
		opts = [strategy: :one_for_one]
		supervise(children, opts)
	end

end
