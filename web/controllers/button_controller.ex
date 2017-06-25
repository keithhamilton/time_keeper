defmodule TimeKeeper.ButtonController do
  use TimeKeeper.Web, :controller

  alias TimeKeeper.Button
  alias TimeKeeper.Job

  def index(conn, _params) do
    records = Repo.all(from j in Job,
      join: b in Button,
      on: b.job_id == j.id,
      select: %{id: b.id, serial_id: b.serial_id, job: j, job_code: j.job_code})
    |> Enum.map(fn r -> struct(Button, r) end)

    render(conn, "index.html", buttons: records)
  end

  def new(conn, _params) do
    changeset = Button.changeset(%Button{})
    jobs = Repo.all(Job)
    render(conn, "new.html", changeset: changeset, jobcodes: jobs)
  end

  def create(conn, %{"button" => button_params}) do
    {id, _} = button_params["jobcodes"]
      |> Integer.parse
    job = Repo.get!(Job, id)

    changeset = Button.changeset(%Button{job: job}, button_params)

    case Repo.insert(changeset) do
      {:ok, _button} ->
        conn
        |> put_flash(:info, "Button created successfully.")
        |> redirect(to: button_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    button = Repo.get!(Button, id)
    job = Repo.get!(Job, button.job_id)

    render(conn, "show.html", button: button, job_name: job.job_name)
  end

  def edit(conn, %{"id" => id}) do
    button = Repo.get!(Button, id)
    jobs = Repo.all(Job)
    changeset = Button.changeset(button)
    render(conn, "edit.html", button: button, changeset: changeset, jobcodes: jobs)
  end

  def update(conn, %{"id" => id, "button" => button_params}) do
    button = Repo.get!(Button, id)
    job = Repo.get!(Job, button_params["jobcodes"])

    change_params = %{"job": job.id, "serial_id": button_params["serial_id"]}
    changeset = Button.changeset(button, change_params)

    case Repo.update(changeset) do
      {:ok, button} ->
        conn
        |> put_flash(:info, "Button updated successfully.")
        |> redirect(to: button_path(conn, :show, button))
      {:error, changeset} ->
        render(conn, "edit.html", button: button, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    button = Repo.get!(Button, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(button)

    conn
    |> put_flash(:info, "Button deleted successfully.")
    |> redirect(to: button_path(conn, :index))
  end
end
