defmodule HTTPDate.Formatter do
    @moduledoc false

    defp integer_to_month(1), do: "Jan"
    defp integer_to_month(2), do: "Feb"
    defp integer_to_month(3), do: "Mar"
    defp integer_to_month(4), do: "Apr"
    defp integer_to_month(5), do: "May"
    defp integer_to_month(6), do: "Jun"
    defp integer_to_month(7), do: "Jul"
    defp integer_to_month(8), do: "Aug"
    defp integer_to_month(9), do: "Sep"
    defp integer_to_month(10), do: "Oct"
    defp integer_to_month(11), do: "Nov"
    defp integer_to_month(12), do: "Dec"

    defp integer_to_short_weekday(1), do: "Mon"
    defp integer_to_short_weekday(2), do: "Tue"
    defp integer_to_short_weekday(3), do: "Wed"
    defp integer_to_short_weekday(4), do: "Thu"
    defp integer_to_short_weekday(5), do: "Fri"
    defp integer_to_short_weekday(6), do: "Sat"
    defp integer_to_short_weekday(7), do: "Sun"

    defp integer_to_weekday(1), do: "Monday"
    defp integer_to_weekday(2), do: "Tuesday"
    defp integer_to_weekday(3), do: "Wednesday"
    defp integer_to_weekday(4), do: "Thursday"
    defp integer_to_weekday(5), do: "Friday"
    defp integer_to_weekday(6), do: "Saturday"
    defp integer_to_weekday(7), do: "Sunday"

    defp pad_integer(integer, length, padchr), do: to_string(integer) |> String.pad_leading(length, padchr)

    @doc false
    def format_date(date, format), do: format_date(date, format, date.calendar.day_of_week(date.year, date.month, date.day)) |> IO.iodata_to_binary

    defp format_date(date, :imf_fixdate, weekday) do
        [
            integer_to_short_weekday(weekday),
            ", ",
            pad_integer(date.day, 2, "0"),
            " ",
            integer_to_month(date.month),
            " ",
            pad_integer(date.year, 4, "0"),
            " ",
            pad_integer(date.hour, 2, "0"),
            ":",
            pad_integer(date.minute, 2, "0"),
            ":",
            pad_integer(date.second, 2, "0"),
            " GMT"
        ]
    end
    defp format_date(date, :rfc850, weekday) do
        [
            integer_to_weekday(weekday),
            ", ",
            pad_integer(date.day, 2, "0"),
            "-",
            integer_to_month(date.month),
            "-",
            pad_integer(date.year, 2, "0") |> String.slice(-2, 2),
            " ",
            pad_integer(date.hour, 2, "0"),
            ":",
            pad_integer(date.minute, 2, "0"),
            ":",
            pad_integer(date.second, 2, "0"),
            " GMT"
        ]
    end
    defp format_date(date, :asctime, weekday) do
        [
            integer_to_short_weekday(weekday),
            " ",
            integer_to_month(date.month),
            " ",
            pad_integer(date.day, 2, " "),
            " ",
            pad_integer(date.hour, 2, "0"),
            ":",
            pad_integer(date.minute, 2, "0"),
            ":",
            pad_integer(date.second, 2, "0"),
            " ",
            pad_integer(date.year, 4, "0")
        ]
    end
end
