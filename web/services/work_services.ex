defmodule TimeKeeper.WorkServices do

  def aggregate_time([first_entry|time_entries], aggregate, key_by) do

    case key_by do
      "job" ->
        primary_key = first_entry.job_code
        secondary_key = first_entry.date
      "date" ->
        primary_key = first_entry.date
        secondary_key = first_entry.job_code
      _ ->
        {:error, "Unsupported key_by type--use \"job\" or \"date\"."}
    end

    job_time = first_entry.time_spent
    primary_hash = Map.get(aggregate, primary_key)

    case primary_hash do
      nil ->
        new_primary_hash = %{secondary_key => job_time}
        aggregate_time(time_entries, Map.put(aggregate, primary_key, new_primary_hash), key_by)
      _ ->
        secondary_hash = Map.get(primary_hash, secondary_key)
        case secondary_hash do
          nil ->
            new_primary_hash = Map.put(primary_hash, secondary_key, job_time)
            aggregate_time(time_entries, Map.put(aggregate, primary_key, new_primary_hash), key_by)
          _ ->
            total_time = Map.get(primary_hash, secondary_key) + job_time
            new_primary_hash = Map.put(primary_hash, secondary_key, total_time)
            aggregate_time(time_entries, Map.put(aggregate, primary_key, new_primary_hash), key_by)
        end
    end
  end

  def aggregate_time([], aggregate, _) do
    aggregate
  end

  def aggregate_time([first_entry|time_entries], key_by) do
    aggregate_time([first_entry|time_entries], %{}, key_by)
  end

  def calc_time_spent(work_object) do
    hours = NaiveDateTime.diff(work_object.updated_at, work_object.inserted_at) / 3600
      |> Float.round(2)

    calendar_date = NaiveDateTime.to_date(work_object.inserted_at)
    %{job_code: work_object.job_code, date: Date.to_string(calendar_date), time_spent: hours}
  end

  defp get_job_times(job_code, time_data, dates) do
    job_hash = Map.get(time_data, job_code)
    date_times = Enum.map(dates, fn d -> Map.get(job_hash, d) end) |> Enum.join(",")
    "#{job_code},#{date_times}\n"
  end

  def sum_time(job_times) do
    foo = job_times
    |> Enum.map(fn w -> Timex.diff(elem(w, 1), elem(w, 0), :minutes) / 60 |> Float.round(2) end)
    IO.inspect foo

    foo
    |> Enum.reduce(fn x, y -> x + y end)
    |> round_hours
  end

  defp round_hours(hours) do

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
      |> Enum.map(fn t -> {elem(t, 0), round_hours(elem(t, 1))} end)
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

  def write_csv(time_data) do
    date_columns = Map.values(time_data)
      |> Enum.map(fn i -> Map.keys(i) end)
      |> Enum.reduce(fn x, y -> Enum.concat(x, y) end)
      |> Enum.uniq
      |> Enum.sort
    {:ok, file} = File.open "/tmp/time.csv", [:write]

    IO.binwrite(file, "#{Enum.concat(["job_code"], date_columns) |> Enum.join(",")}\n")

    Map.keys(time_data)
    |> Enum.filter(fn e -> e != "AFK" end)
    |> Enum.map(fn t -> get_job_times(t, time_data, date_columns) end)
    |> Enum.map(fn jt -> IO.binwrite(file, jt) end)

    File.close(file)
    "/tmp/time.csv"
  end
end
