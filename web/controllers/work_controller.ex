defmodule TimeKeeper.WorkController do
  use TimeKeeper.Web, :controller

  alias TimeKeeper.Work

  def open(conn, button_pin) do
    [button|_] = Repo.all(from b in Button,
      where: b.serial_id == ^button_pin,
      select: b)

    job = Repo.get!(Job, button.job_id)
    work = Work.changeset(%Work{job: job}, %{})

    case Repo.insert(work) do
      {:ok, _} ->
        IO.puts "Work begun on #{job.job_code}"
      {:error, _} ->
        conn
        |> put_status(:error)
        |> send_resp(500, "Error beginning new work")
    end
  end

  def close(conn, work_object, changes) do
    current_job = Repo.all(from j in Job, where: j.id == ^work_object.job_id)
      |> first
    changeset = Work.changeset(work_object, %{job: current_job, complete: true})

    case Repo.update(changeset) do
      {:ok, _} ->
        IO.puts "Work complete on #{changes.job.job_code}"
      {:error, _} ->
        conn
        |> put_status(:error)
        |> send_resp(500, "Error closing out previous work")
    end
  end

  def switch(conn, %{"button_pin" => button_pin}) do
    incomplete_work = Repo.all(from w in Work, where: not w.complete)

    if length(incomplete_work) > 0 do
      Work.close(conn, first(incomplete_work))
    end

    Work.open(conn, button_pin)

    conn
    |> put_status(:ok)
    |> send_resp(200, "All good")

  end
end

  # def index(conn, _params) do
  #   work = Repo.all(Work)
  #   render(conn, "index.html", work: work)
  # end
  #
  # def new(conn, _params) do
  #   changeset = Work.changeset(%Work{})
  #   render(conn, "new.html", changeset: changeset)
  # end
  #
  # def create(conn, %{"work" => work_params}) do
  #   changeset = Work.changeset(%Work{}, work_params)
  #
  #   case Repo.insert(changeset) do
  #     {:ok, _work} ->
  #       conn
  #       |> put_flash(:info, "Work created successfully.")
  #       |> redirect(to: work_path(conn, :index))
  #     {:error, changeset} ->
  #       render(conn, "new.html", changeset: changeset)
  #   end
  # end
  #
  # def show(conn, %{"id" => id}) do
  #   work = Repo.get!(Work, id)
  #   render(conn, "show.html", work: work)
  # end
  #
  # def edit(conn, %{"id" => id}) do
  #   work = Repo.get!(Work, id)
  #   changeset = Work.changeset(work)
  #   render(conn, "edit.html", work: work, changeset: changeset)
  # end
  #
  # def update(conn, %{"id" => id, "work" => work_params}) do
  #   work = Repo.get!(Work, id)
  #   changeset = Work.changeset(work, work_params)
  #
  #   case Repo.update(changeset) do
  #     {:ok, work} ->
  #       conn
  #       |> put_flash(:info, "Work updated successfully.")
  #       |> redirect(to: work_path(conn, :show, work))
  #     {:error, changeset} ->
  #       render(conn, "edit.html", work: work, changeset: changeset)
  #   end
  # end
  #
  # def delete(conn, %{"id" => id}) do
  #   work = Repo.get!(Work, id)
  #
  #   # Here we use delete! (with a bang) because we expect
  #   # it to always work (and if it does not, it will raise).
  #   Repo.delete!(work)
  #
  #   conn
  #   |> put_flash(:info, "Work deleted successfully.")
  #   |> redirect(to: work_path(conn, :index))
  # end
