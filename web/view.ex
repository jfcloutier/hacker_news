defmodule News.View do

  use Phoenix.View, root: "web/templates/reflux" # Change this to switch to alternate templating (ng, fluxxor or reflux)

  # The quoted expression returned by this block is applied
  # to this module and all other views that use this module.
  using do
    quote do
      # Import common functionality
      import News.Router.Helpers

      # Use Phoenix.HTML to import all HTML functions (forms, tags, etc)
      use Phoenix.HTML
    end
  end

  # Functions defined here are available to all other views/templates
end
