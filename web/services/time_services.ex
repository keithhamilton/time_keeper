defmodule TimeKeeper.TimeServices do
  @moduledoc """
  Time-related utility methods
  """

  ### Private Functions ########################################################
  @spec first_half(NaiveDateTime) :: Tuple.t
  @spec second_half(NaiveDateTime) :: Tuple.t

  defp first_half(date) do
    start_date = date
    |> Timex.shift(days: (date.day - 1) * -1)
    |> Timex.set(hour: 0, minute: 0, second: 0)

    end_date = date
    |> Timex.shift(days: 15 - date.day)
    |> Timex.set(hour: 23, minute: 59, second: 59)

    {start_date, end_date}
  end

  defp second_half(date) do
    last_of_month = date |> Timex.days_in_month

    start_date = date
    |> Timex.shift(days: (date.day - 16) * -1)
    |> Timex.set(hour: 0, minute: 0, second: 0)

    end_date = date
    |> Timex.shift(days: last_of_month - date.day)
    |> Timex.set(hour: 23, minute: 59, second: 59)

    {start_date, end_date}
  end


  ### Public Functions #########################################################
  @spec current_pay_period() :: function
  @spec current_pay_period(NaiveDateTime.t) :: Tuple.t

  @doc """
    Initializes current_pay_period with the date set to today.
  """
  def current_pay_period do
    current_pay_period(Timex.now)
  end

  @doc """
  Given a date, returns the pay period of which that date is a part.

  ## Parameters
    - date: NaiveDateTime representing a day of the year
  """
  def current_pay_period(date) do
    case date.day do
      x when x <= 15 ->
        first_half(date)
      _ ->
        second_half(date)
    end
  end
end
