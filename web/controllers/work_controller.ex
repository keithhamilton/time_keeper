defmodule TimeKeeper.WorkController do
  use TimeKeeper.Web, :controller

  alias TimeKeeper.Button
  alias TimeKeeper.Job
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

  def close(conn, work_object) do
    [current_job|_] = Repo.all(from j in Job, where: j.id == ^work_object.job_id)
    changeset = Work.changeset(work_object, %{job: current_job, complete: true})

    case Repo.update(changeset) do
      {:ok, _} ->
        IO.puts "Work complete on #{current_job.job_code}"
      {:error, _} ->
        conn
        |> put_status(:error)
        |> send_resp(500, "Error closing out previous work")
    end
  end

  def switch(conn, %{"button_pin" => button_pin}) do
    incomplete_work = Repo.all(from w in Work, where: not w.complete)

    if length(incomplete_work) > 0 do
      [work_object|_] = incomplete_work
      TimeKeeper.WorkController.close(conn, work_object)
    end

    TimeKeeper.WorkController.open(conn, button_pin)

    conn
    |> put_status(:ok)
    |> send_resp(200, "All good")

  end

  def round_time_spent({whole_hour, hour_fraction}) do
    cond do
      hour_fraction <= 15 ->
        whole_hour + 0.25
      hour_fraction > 15 and hour_fraction <= 30 ->
        whole_hour + 0.5
      hour_fraction > 30 and hour_fraction <= 45 ->
        whole_hour + 0.75
      hour_fraction > 45 ->
        whole_hour + 1.0
    end
  end

  def calc_time_spent(work_object) do
    hours = NaiveDateTime.diff(work_object.updated_at, work_object.inserted_at) / 3600
      |> Float.round(2)

    time_spent = {hours |> Float.floor, (hours - Float.floor(hours)) * 60 |> Float.floor}
      |> TimeKeeper.WorkController.round_time_spent

    calendar_date = NaiveDateTime.to_date(work_object.inserted_at)

    %{job_code: work_object.job_code, date: calendar_date, time_spent: time_spent}

  end

  def aggregate_time([first_entry|time_entries], aggregate) do
    date_string = Date.to_string(first_entry.date)

    if Map.has_key?(aggregate, date_string) do
      date_hash = Map.get(aggregate, date_string)

      if Map.has_key?(date_hash, first_entry.job_code) do
        total_time = Map.get(date_hash, first_entry.job_code) + first_entry.time_spent
        new_date_hash = Map.put(date_hash, first_entry.job_code, total_time)
        new_aggregate = Map.put(aggregate, date_string, new_date_hash)
        aggregate_time(time_entries, new_aggregate)
      else
        new_date_hash = Map.put(date_hash, first_entry.job_code, first_entry.time_spent)
        new_aggregate = Map.put(aggregate, date_string, new_date_hash)
        aggregate_time(time_entries, new_aggregate)
      end
    else
      date_hash = %{first_entry.job_code => first_entry.time_spent}
      new_aggregate = Map.put(aggregate, date_string, date_hash)
      aggregate_time(time_entries, new_aggregate)
    end
  end

  def aggregate_time([], aggregate) do
    aggregate
  end

  def aggregate_time([first_entry|time_entries]) do
    aggregate_time([first_entry|time_entries], %{})
  end

  def job_work(conn, %{"start_date" => start_date, "end_date" => end_date}) do
    {_, start_dt, _} = DateTime.from_iso8601("#{start_date}T00:00:00Z")
    {_, end_dt, _} = DateTime.from_iso8601("#{end_date}T00:00:00Z")

    all_work = Repo.all(from w in Work,
      join: j in Job,
      where: j.id == w.job_id and w.inserted_at >= ^start_dt and w.inserted_at <= ^end_dt and w.complete,
      select: %{inserted_at: w.inserted_at, updated_at: w.updated_at, job_code: j.job_code})

    IO.puts "Found #{length(all_work)} jobs!"

    work_time = Enum.map(all_work, fn w -> calc_time_spent(w) end)
      |> aggregate_time

    conn
    |> put_status(:ok)
    |> send_resp(200, Poison.encode(work_time))
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
