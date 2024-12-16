defmodule Tgw.Repo.Migrations.Triggers do
  use Ecto.Migration

  def change do
    execute """
    CREATE FUNCTION notify_task_update()
    RETURNS trigger AS $$
    BEGIN
    PERFORM pg_notify('status_updates', 'task_update');
    RETURN NULL;
    END
    $$ LANGUAGE plpgsql
    """,
      "DROP FUNCTION notify_task_update"

    execute """
    CREATE FUNCTION notify_job_update()
    RETURNS trigger AS $$
    BEGIN
    PERFORM pg_notify('status_updates', 'job_update');
    RETURN NULL;
    END
    $$ LANGUAGE plpgsql
    """,
      "DROP FUNCTION notify_job_update"

    execute """
    CREATE TRIGGER task_update
    AFTER UPDATE OR INSERT ON tasks
    FOR EACH STATEMENT
    EXECUTE PROCEDURE notify_task_update()
    """,
      "DROP TRIGGER task_update ON tasks"

    execute """
    CREATE TRIGGER job_update
    AFTER UPDATE OR INSERT ON jobs
    FOR EACH STATEMENT
    EXECUTE PROCEDURE notify_job_update()
    """,
      "DROP TRIGGER job_update ON jobs"
  end
end
