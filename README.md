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
