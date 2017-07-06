defmodule TimeKeeper.TimeServices do
  @timezone "America/Los_Angeles"

  def current_pay_period do
    current_pay_period(Timex.now)
  end

  def current_pay_period(date) do
    case date.day do
      x when x <= 15 ->
        [date
        |> Timex.shift(days: (date.day - 1) * -1)
        |> Timex.set(hour: 0, minute: 0, second: 0),
        date
        |> Timex.shift(days: 15 - date.day)
        |> Timex.set(hour: 23, minute: 59, second: 59)]
      _ ->
        last_of_month = date |> Timex.days_in_month
        [date
        |> Timex.shift(days: (date.day - 16) * -1)
        |> Timex.set(hour: 0, minute: 0, second: 0),
        date
        |> Timex.shift(days: last_of_month - date.day)
        |> Timex.set(hour: 23, minute: 59, second: 59)]
    end
  end
end
