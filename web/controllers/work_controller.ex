defmodule TimeKeeper.WorkController do
  @moduledoc """
  """
  use TimeKeeper.Web, :controller

  alias TimeKeeper.{Button, Job, TimeServices, User, Work, WorkServices}

  @doc """
  """
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

  def dashboard(conn, %{}) do
    current_user = Addict.Helper.current_user(conn)
    case current_user do
      nil ->
        conn
        |> redirect(to: "/register")
      _ ->
        [start_date, end_date] = TimeServices.current_pay_period
        total_time = Repo.all(from w in Work,
          join: j in Job,
          where: j.job_code != "AFK",
          where: j.id == w.job_id and w.inserted_at >= ^start_date and w.inserted_at <= ^end_date and w.complete,
          select: {w.inserted_at, w.updated_at})
        |> WorkServices.sum_time

        [current_job|_] = Repo.all(from w in Work,
        join: j in Job,
        where: j.id == w.job_id,
        where: not w.complete,
        select: j.job_name)

        conn
        |> put_status(:ok)
        |> render("dashboard.html", total_time: total_time,
          user_board: current_user.name,
          current_job: current_job)
    end
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

  def edit(conn, %{"id" => id}) do
    [work|_] = Repo.all(from w in Work,
      where: w.id == ^id,
      select: w)
    changeset = Work.changeset(work)
    render(conn, "edit.html", work: work, changeset: changeset)
  end

  def index(conn, _params) do
    work = Repo.all(Work)
    render(conn, "index.html", work: work)
  end

  def job_work(conn, %{"start_date" => start_date, "end_date" => end_date, "download" => download}) do
    {_, start_dt, _} = DateTime.from_iso8601("#{start_date}T00:00:00Z")
    {_, end_dt, _} = DateTime.from_iso8601("#{end_date}T23:59:59Z")

    all_work = Repo.all(from w in Work,
      join: j in Job,
      where: j.id == w.job_id and w.inserted_at >= ^start_dt and w.inserted_at <= ^end_dt and w.complete,
      select: %{inserted_at: w.inserted_at, updated_at: w.updated_at, job_code: j.job_code})

    IO.puts "Found #{length(all_work)} jobs!"

    case download do
      "browser" ->
        download_link = "/work/#{start_date}/#{end_date}/time_report"
        time_records = Enum.map(all_work, fn w -> WorkServices.calc_time_spent(w) end)
        |> WorkServices.aggregate_time("date")
        |> WorkServices.round_job_time
        |> Map.to_list
        |> Enum.map(fn t -> %{date: elem(t, 0), values: elem(t, 1) |> Map.to_list} end)

        conn
        |> put_status(:ok)
        |> render("work_report.html", records: time_records, download_link: download_link)

      _ ->
        response_text = Enum.map(all_work, fn w -> WorkServices.calc_time_spent(w) end)
        |> WorkServices.aggregate_time("job")
        |> WorkServices.round_job_time
        |> WorkServices.write_csv

        conn
        |> put_status(:ok)
        |> put_resp_content_type("text/csv")
        |> send_file(200, response_text)
    end
  end

  def job_work(conn, %{}) do
    [start_date, end_date] = TimeServices.current_pay_period
    |> Enum.map(fn d -> DateTime.to_date(d) |> Date.to_string end)
    IO.puts start_date
    IO.puts end_date
    conn
    |> redirect(to: "/work/#{start_date}/#{end_date}/browser")
  end

  def new(conn, _params) do
    changeset = Work.changeset(%Work{})
    render(conn, "new.html", changeset: changeset)
  end

  def open(conn, button_pin, user_id) do
    [button|_] = Repo.all(from b in Button,
      where: b.serial_id == ^button_pin,
      select: b)

    job = Repo.get!(Job, button.job_id)
    work = Work.changeset(%Work{job: job, user_id: user_id}, %{})

    case Repo.insert(work) do
      {:ok, _} ->
        IO.puts "Work begun on #{job.job_code}"
      {:error, _} ->
        conn
        |> put_status(:error)
        |> send_resp(500, "Error beginning new work")
    end
  end

  def show(conn, %{"id" => id}) do
    work = Repo.get!(Work, id)
    render(conn, "show.html", work: work)
  end

  def switch(conn, %{"button_pin" => button_pin, "serial" => serial_board}) do
    IO.puts "Received signal from button #{button_pin}!"
    [user|_] = Repo.all(from u in User,
    where: u.name == ^serial_board,
    select: u)

    incomplete_work = Repo.all(from w in Work,
    where: not w.complete and w.user_id == ^user.id)

    if length(incomplete_work) > 0 do
      [work_object|_] = incomplete_work
      TimeKeeper.WorkController.close(conn, work_object)
    end

    TimeKeeper.WorkController.open(conn, button_pin, user.id)

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
    current_user = Addict.Helper.current_user(conn)
    buttons = Repo.all(from b in Button,
      join: u in User,
      join: j in Job,
      where: u.id == ^current_user.id,
      where: b.job_id == j.id,
      select: %{serial_id: b.serial_id, job_code: j.job_code},
      order_by: b.id)

    |> Enum.map(fn r -> struct(Button, r) end)

    render(conn, "switch.html", buttons: buttons, user: current_user)
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

end
