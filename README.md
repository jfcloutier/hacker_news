Hacker News
===========

A demo Elixir/OTP Web application that:

1. Retrieves Hacker News stories via Firebase
2. Delegates title translations to registered processes in clustered nodes running https://github.com/jfcloutier/translator

This was developed for the Portland (Maine) Erlang & Elixir Meetup 

To start:

1. Store your Google API key in a file named 'google_api.key' in the project's home directory
2. Execute: iex --name something_unique@your_ip_address --cookie oreo -S mix phoenix.server
3. Visit `localhost:4000` from your browser.


To switch between the three alternate template implementations, modify web/view.ex

defmodule News.View do

  use Phoenix.View, root: "web/templates/reflux" # Change this to switch to alternate templating (ng, fluxxor or reflux)
....

The alternatives are web/template/ng, web/template/fluxxor and web/template/reflux (the default)

JSEX 2.0 bug
============

ExFirebase depends on an old version (2.0) of JSEX served by Hex. It has a bug.

In deps/jsex/lib/jsex.ex, prepend this clause to format_key/2

  defp format_key(key, { _, :binary, _ }), do: key

