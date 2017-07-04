defmodule TimeKeeper.WorkController do
  use TimeKeeper.Web, :controller

  alias TimeKeeper.Button
  alias TimeKeeper.Job
  alias TimeKeeper.User
  alias TimeKeeper.Work

  # def aggregate_time([first_entry|time_entries], aggregate) do
  #   date_string = Date.to_string(first_entry.date)
  #
  #   if Map.has_key?(aggregate, date_string) do
  #     date_hash = Map.get(aggregate, date_string)
  #
  #     if Map.has_key?(date_hash, first_entry.job_code) do
  #       total_time = Map.get(date_hash, first_entry.job_code) + first_entry.time_spent
  #       new_date_hash = Map.put(date_hash, first_entry.job_code, total_time)
  #       new_aggregate = Map.put(aggregate, date_string, new_date_hash)
  #       aggregate_time(time_entries, new_aggregate)
  #     else
  #       new_date_hash = Map.put(date_hash, first_entry.job_code, first_entry.time_spent)
  #       new_aggregate = Map.put(aggregate, date_string, new_date_hash)
  #       aggregate_time(time_entries, new_aggregate)
  #     end
  #   else
  #     date_hash = %{first_entry.job_code => first_entry.time_spent}
  #     new_aggregate = Map.put(aggregate, date_string, date_hash)
  #     aggregate_time(time_entries, new_aggregate)
  #   end
  # end

  def aggregate_time([first_entry|time_entries], aggregate) do
    IO.puts "#{length(time_entries)} jobs remain"
    job_code = first_entry.job_code
    job_date = first_entry.date
    job_hash = Map.get(aggregate, job_code)
    job_time = first_entry.time_spent

    case job_hash do
      nil ->
        new_job_hash = %{first_entry.date => first_entry.time_spent}
        aggregate_time(time_entries, Map.put(aggregate, job_code, new_job_hash))
      _ ->
        date_hash = Map.get(job_hash, job_date)

        case date_hash do
          nil ->
            new_job_hash = Map.put(job_hash, job_date, job_time)
            aggregate_time(time_entries, Map.put(aggregate, job_code, new_job_hash))
          _ ->
            total_time = Map.get(job_hash, job_date) + job_time
            new_job_hash = Map.put(job_hash, job_date, total_time)
            aggregate_time(time_entries, Map.put(aggregate, job_code, new_job_hash))
        end
    end
  end

  def aggregate_time([], aggregate) do
    aggregate
  end

  def aggregate_time([first_entry|time_entries]) do
    aggregate_time([first_entry|time_entries], %{})
  end

  def calc_time_spent(work_object) do
    hours = NaiveDateTime.diff(work_object.updated_at, work_object.inserted_at) / 3600
      |> Float.round(2)

    calendar_date = NaiveDateTime.to_date(work_object.inserted_at)
    %{job_code: work_object.job_code, date: Date.to_string(calendar_date), time_spent: hours}
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

  def job_work(conn, %{"start_date" => start_date, "end_date" => end_date}) do
    {_, start_dt, _} = DateTime.from_iso8601("#{start_date}T00:00:00Z")
    {_, end_dt, _} = DateTime.from_iso8601("#{end_date}T00:00:00Z")

    all_work = Repo.all(from w in Work,
      join: j in Job,
      where: j.id == w.job_id and w.inserted_at >= ^start_dt and w.inserted_at <= ^end_dt and w.complete,
      select: %{inserted_at: w.inserted_at, updated_at: w.updated_at, job_code: j.job_code})

    IO.puts "Found #{length(all_work)} jobs!"

    response_text = Enum.map(all_work, fn w -> calc_time_spent(w) end)
      |> aggregate_time
      |> round_job_time
      |> write_csv

    conn
    |> put_status(:ok)
    |> put_resp_content_type("text/csv")
    |> send_file(200, response_text)
  end

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

  def round_hours(hours) do

    {whole_hour, hour_fraction} = {hours |> Float.floor,
                                  (hours - Float.floor(hours)) * 60 |> Float.floor}
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

  def round_job_time(aggregate, keys, rounded_aggregate) do
    if length(keys) == 0 do
      round_job_time(:finish, rounded_aggregate)
    else
      [first|rest] = keys
      day_hours = Map.get(aggregate, first)
      |> Map.to_list
      |> Enum.map(fn t -> {elem(t, 0), TimeKeeper.WorkController.round_hours(elem(t, 1))} end)
      |> Enum.into(%{})

      new_aggregate = Map.put(rounded_aggregate, first, day_hours)
      round_job_time(Map.drop(aggregate, [first]), rest, new_aggregate)
    end
  end

  def round_job_time(_, rounded_aggregate) do
    rounded_aggregate
  end

  def round_job_time(aggregate) do
    round_job_time(aggregate, Map.keys(aggregate), %{})
  end

  def switch(conn, %{"button_pin" => button_pin, "serial" => serial}) do
    IO.puts "Received signal from button #{button_pin}!"
    incomplete_work = Repo.all(from w in Work,
    join: j in Job,
    join: u in User,
    where: j.id == w.job_id,
    where: j.user_id == u.id,
    where: u.board == ^serial,
    where: not w.complete)

    if length(incomplete_work) > 0 do
      [work_object|_] = incomplete_work
      TimeKeeper.WorkController.close(conn, work_object)
    end

    TimeKeeper.WorkController.open(conn, button_pin)

    job_code = Repo.all(from b in Button,
    join: j in Job,
    where: j.id == b.job_id,
    where: b.serial_id == ^button_pin,
    select: j.job_code)

    resp = "#{job_code}"

    conn
    |> put_status(:ok)
    |> send_resp(200, resp)
  end

  def switch_manual(conn, _params) do
    buttons = Repo.all(from b in Button,
      join: j in Job,
      where: b.job_id == j.id,
      select: %{serial_id: b.serial_id, job: b.job_id, job_code: j.job_code})

    |> Enum.map(fn r -> struct(Button, r) end)

    render(conn, "switch.html", buttons: buttons)
  end

  def index(conn, _params) do
    work = Repo.all(Work)
    render(conn, "index.html", work: work)
  end

  def edit(conn, %{"id" => id}) do
    [work|_] = Repo.all(from w in Work,
      where: w.id == ^id,
      select: w)
    changeset = Work.changeset(work)
    render(conn, "edit.html", work: work, changeset: changeset)
  end

  def update(conn, %{"id" => id, "work" => work_params}) do
    work = Repo.get!(Work, id)
    changeset = Work.changeset(work, work_params)

    case Repo.update(changeset) do
      {:ok, work} ->
        conn
        |> put_flash(:info, "Work updated successfully.")
        |> redirect(to: work_path(conn, :show, work))
      {:error, changeset} ->
        render(conn, "edit.html", work: work, changeset: changeset)
    end
  end

  def get_job_times(job_code, time_data, dates) do
    job_hash = Map.get(time_data, job_code)
    date_times = Enum.map(dates, fn d -> Map.get(job_hash, d) end) |> Enum.join(",")
    "#{job_code},#{date_times}\n"
  end

  def write_csv(time_data) do
    date_columns = Map.values(time_data)
      |> Enum.map(fn i -> Map.keys(i) end)
      |> Enum.reduce(fn x, y -> Enum.concat(x, y) end)
      |> Enum.uniq
      |> Enum.sort
    {:ok, file} = File.open "/tmp/time.csv", [:write]

    IO.binwrite(file, "#{Enum.concat(["job_code"], date_columns) |> Enum.join(",")}\n")

    Enum.map(Map.keys(time_data), fn t -> get_job_times(t, time_data, date_columns) end)
      |> Enum.map(fn jt -> IO.binwrite(file, jt) end)

    File.close(file)
    "/tmp/time.csv"
  end

  def new(conn, _params) do
    changeset = Work.changeset(%Work{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"work" => work_params}) do
    changeset = Work.changeset(%Work{}, work_params)

    case Repo.insert(changeset) do
      {:ok, _work} ->
        conn
        |> put_flash(:info, "Work created successfully.")
        |> redirect(to: work_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    work = Repo.get!(Work, id)
    render(conn, "show.html", work: work)
  end



  def delete(conn, %{"id" => id}) do
    work = Repo.get!(Work, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(work)

    conn
    |> put_flash(:info, "Work deleted successfully.")
    |> redirect(to: work_path(conn, :index))
  end
end
