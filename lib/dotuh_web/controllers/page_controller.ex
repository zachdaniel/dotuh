defmodule DotuhWeb.PageController do
  use DotuhWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
