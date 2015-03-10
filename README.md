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

ReactJS templates
=================

To translate .jsx files to .js:
   1. make sure jsx support is installed (via npm install jsx)
   2. cd to the directory where the jsx files are
   3. jsx -x jsx ./ ./ 

To collate the app's .js file and the js it requires into a bundle.js
   1. make sure browserify is installed (via npm install browserify)
   2. cd to the directory where the js file is
   3. browserify app.js -o bundle.js

JSEX 2.0 bug
============

ExFirebase depends on an old version (2.0) of JSEX served by Hex. It has a bug.

In deps/jsex/lib/jsex.ex, prepend this clause to format_key/2

  defp format_key(key, { _, :binary, _ }), do: key

