defmodule News.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ~w(html)
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ~w(json)
  end

  scope "/", News do
    pipe_through :browser

    get "/", PageController, :index
  end

	scope "/api", News do
		pipe_through :api

		resources "/stories", StoriesController, only: [:index]
  end
end
