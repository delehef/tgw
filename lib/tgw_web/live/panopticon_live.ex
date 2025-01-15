defmodule TgwWeb.PanopticonLive do
  use TgwWeb, :live_view

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Tgw.PubSub, "status_updates")

    {
      :ok,
      socket
      |> assign(:tasks, Tgw.Db.Task.in_flight())
      |> assign(:in_flight, Tgw.Db.Job.in_flight())
      |> assign(:failed, Tgw.Db.Job.failed())
    }
  end

  def handle_info({:notification, "task_update"}, socket) do
    {
      :noreply,
      socket
      |> assign(:tasks, Tgw.Db.Task.in_flight())
    }
  end

  def handle_info({:notification, "job_update"}, socket) do
    {
      :noreply,
      socket
      |> assign(:in_flight, Tgw.Db.Job.in_flight())
      |> assign(:failed, Tgw.Db.Job.failed())
    }
  end
end
