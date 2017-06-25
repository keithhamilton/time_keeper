defmodule TimeKeeper.JobController do
  use TimeKeeper.Web, :controller

  alias TimeKeeper.Job
  alias TimeKeeper.Button
  alias TimeKeeper.Work

  def index(conn, _params) do
    jobs = Repo.all(Job)
    render(conn, "index.html", jobs: jobs)
  end

  def new(conn, _params) do
    changeset = Job.changeset(%Job{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"job" => job_params}) do
    changeset = Job.changeset(%Job{}, job_params)

    case Repo.insert(changeset) do
      {:ok, _job} ->
        conn
        |> put_flash(:info, "Job created successfully.")
        |> redirect(to: job_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    job = Repo.get!(Job, id)
    render(conn, "show.html", job: job)
  end

  def edit(conn, %{"id" => id}) do
    job = Repo.get!(Job, id)
    changeset = Job.changeset(job)
    render(conn, "edit.html", job: job, changeset: changeset)
  end

  def update(conn, %{"id" => id, "job" => job_params}) do
    job = Repo.get!(Job, id)
    changeset = Job.changeset(job, job_params)

    case Repo.update(changeset) do
      {:ok, job} ->
        conn
        |> put_flash(:info, "Job updated successfully.")
        |> redirect(to: job_path(conn, :show, job))
      {:error, changeset} ->
        render(conn, "edit.html", job: job, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    job = Repo.get!(Job, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(job)

    conn
    |> put_flash(:info, "Job deleted successfully.")
    |> redirect(to: job_path(conn, :index))
  end

  def switch(conn, %{"new_job_id" => new_id}) do

    [button|_] = Repo.all(from b in Button,
      where: b.serial_id == ^new_id,
      select: b)
    job = Repo.get!(Job, button.job_id)

    current_job = Repo.first(from w in Work, where: not complete)

    if current_job != nil do
      changeset = Work.changeset(current_job, %{complete: true})
      case Repo.update(changeset) do
        {:ok, updated} ->
          IO.puts "Work complete on #{job.job_code}"
        {:error, changeset} ->
          conn
          |> put_status(:error)
          |> send_resp(500, "Error closing out previous work")
      end
    end

    work = Work.changeset(%Work{complete: false, job: job}, {})

    case Repo.update(work) do
      {:ok, work} ->
        IO.puts "Work begun on #{job.job_code}"
      {:error, changeset} ->
        conn
        |> put_status(:error)
        |> send_resp(500, "Error closing out previous work")
    end

    IO.puts job.job_name
    IO.puts job.job_code

    conn
    |> put_status(:ok)
    |> send_resp(200, "All good")

  end

end
