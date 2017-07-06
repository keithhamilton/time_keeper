defmodule TimeKeeper.WorkServices do
  @moduledoc """
  Business logic associated with Work objects
  """
  @type job_entry :: %{String.t => String.t, String.t => String.t, String.t => String.t}
  @type job_time :: {Timex.Date, Timex.Date}

  ### Private Functions ########################################################
  @spec aggregate_keys(job_entry, String.t) :: Tuple.t
  @spec get_job_times(String.t, Map.t, [String.t]) :: String.t
  @spec round_hours(Float.t) :: Float.t

  defp aggregate_keys(entry, key_by) do
    case key_by do
      "job" ->
        {entry.job_code, entry.date}
      "date" ->
        {entry.date, entry.job_code}
      _ ->
        {:error, "Unsupported key_by type--use \"job\" or \"date\"."}
    end
  end

  defp get_job_times(job_code, time_data, dates) do
    job_hash = Map.get(time_data, job_code)
    date_times = Enum.map(dates, fn d -> Map.get(job_hash, d) end) |> Enum.join(",")
    "#{job_code},#{date_times}\n"
  end

  defp round_hours(time) do
    {whole_hour, hour_fraction} = {time |> Float.floor,
                                  (time - Float.floor(time)) * 60 |> Float.floor}
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

  ### Public Functions #########################################################
  @spec aggregate_time([job_entry], Map.t, String.t) :: function
  @spec aggregate_time(List.t, Map.t) :: Map.t
  @spec aggregate_time([TimeKeeper.WorkServices.job_entry], String.t) :: function
  @spec calc_time_spent(TimeKeeper.Work) :: TimeKeeper.WorkServices.job_entry
  @spec sum_time([TimeKeeper.WorkServices.job_time]) :: Float.t
  @spec round_job_time([String.t], Map.t, Map.t) :: function
  @spec round_job_time([String.t], Map.t, Map.t) :: Map.t
  @spec round_job_time(Map.t) :: function
  @spec write_csv(Map.t) :: String.t

  @doc """
  Aggregates time spent on job entries by job code or date.

  ## Parameters

    - [first_entry|time_entries]: list containing job entries
    - aggregate: map containing aggregated time entries
    - key: string denoting which primary key to use ("job" or "date")
  """
  def aggregate_time([first_entry|time_entries], aggregate, key_by) do

    {primary_key, secondary_key} = aggregate_keys(first_entry, key_by)
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

  @doc """
  Returns finished aggregated time Map when entries have been exhausted.

    ## Parameters

    - []: exhausted list of job entries
    - aggregate: map containing aggregated time entries
  """
  def aggregate_time([], aggregate, _) do
    aggregate
  end

  @doc """
  Initializes time aggregation by creating an empty map into which time can be
  aggregated.

    - [first_entry|time_entries]: list containing job entries
    - key: string denoting which primary key to use ("job" or "date")
  """
  def aggregate_time([first_entry|time_entries], key_by) do
    aggregate_time([first_entry|time_entries], %{}, key_by)
  end

  @doc """
  Takes a TimeKeeper.Work model from the database and converts it into a new Map
  that contains the computed amount of time spent on the Work entry.

  ## Parameters
    - work_object: the TimeKeeper.Work object to process
  """
  def calc_time_spent(work_object) do
    hours = NaiveDateTime.diff(work_object.updated_at, work_object.inserted_at) / 3600
      |> Float.round(2)

    calendar_date = NaiveDateTime.to_date(work_object.inserted_at)
    %{job_code: work_object.job_code, date: Date.to_string(calendar_date), time_spent: hours}
  end

  @doc """
  Sums a list of inserted/updated time tuples and sums them without respect to
  project or job code.

  ## Parameters
    - job_times: list of TimeKeeper.WorkServices.job_time tuples
  """
  def sum_time(job_times) do
    job_times
    |> Enum.map(fn w -> Timex.diff(elem(w, 1), elem(w, 0), :minutes) / 60 |> Float.round(2) end)
    |> Enum.reduce(fn x, y -> x + y end)
    |> round_hours
  end

  @doc """
  Rounds aggregated time up to the nearest quarter-hour to conform with Aura
  Time's constraints.

  ## Parameters
    - [keys]: the keys for the aggregated time Map
    - aggregate: Map of aggregated time (by job code *or* date)
    - rounded_aggregate: Map of rounded time, aggregated by same key as `aggregate`
  """
  def round_job_time([first_key|rest_keys], aggregate, rounded_aggregate) do
    day_hours = Map.get(aggregate, first_key)
    |> Map.to_list
    |> Enum.map(fn t -> {elem(t, 0), round_hours(elem(t, 1))} end)
    |> Enum.into(%{})

    new_aggregate = Map.put(rounded_aggregate, first_key, day_hours)
    round_job_time(rest_keys, aggregate, new_aggregate)
  end

  @doc """
  Returns finished, rounded aggregated time Map when entries have been exhausted.

  ## Parameters
    - []: exhausted list of aggregate keys
    - _: aggregate Map (ignored)
    - rounded_aggregate: map containing rounded, aggregated time entries
  """
  def round_job_time([], _, rounded_aggregate) do
    rounded_aggregate
  end

  @doc """
  Initializes rounded time aggregation by creating an empty map into which time
  can be aggregated.

  ## Parameters
    - aggregate: Map of aggregated time (by job code *or* date)
  """
  def round_job_time(aggregate) do
    round_job_time(Map.keys(aggregate), aggregate, %{})
  end

  @doc """
  Writes a set of aggregated time entries (keyed by date) to a CSV file in the
  temp directory. Returns the path to the csv file for download.

  ## Parameters
    - time_data: Map of aggregated, rounded time entries, keyed by date
  """
  def write_csv(time_data) do

    csv_path = "/tmp/time.csv"

    date_columns = Map.values(time_data)
      |> Enum.map(fn i -> Map.keys(i) end)
      |> Enum.reduce(fn x, y -> Enum.concat(x, y) end)
      |> Enum.uniq
      |> Enum.sort
    {:ok, file} = File.open csv_path, [:write]

    IO.binwrite(file, "#{Enum.concat(["job_code"], date_columns) |> Enum.join(",")}\n")

    Map.keys(time_data)
    # filter out AFK, since we don't care what you do on your own time
    |> Enum.filter(fn e -> e != "AFK" end)
    |> Enum.map(fn t -> get_job_times(t, time_data, date_columns) end)
    |> Enum.map(fn jt -> IO.binwrite(file, jt) end)

    File.close(file)
    csv_path
  end
end
