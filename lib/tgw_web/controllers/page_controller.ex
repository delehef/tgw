defmodule TgwWeb.PageController do
  use TgwWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def workers(conn, _) do
    render(conn, :workers, workers: Tgw.Db.Worker.list())
  end
end
