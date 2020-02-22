defmodule HTTPDate.Parser do
    @moduledoc false

    defp month_to_integer("Jan" <> unparsed), do: { 1, unparsed }
    defp month_to_integer("Feb" <> unparsed), do: { 2, unparsed }
    defp month_to_integer("Mar" <> unparsed), do: { 3, unparsed }
    defp month_to_integer("Apr" <> unparsed), do: { 4, unparsed }
    defp month_to_integer("May" <> unparsed), do: { 5, unparsed }
    defp month_to_integer("Jun" <> unparsed), do: { 6, unparsed }
    defp month_to_integer("Jul" <> unparsed), do: { 7, unparsed }
    defp month_to_integer("Aug" <> unparsed), do: { 8, unparsed }
    defp month_to_integer("Sep" <> unparsed), do: { 9, unparsed }
    defp month_to_integer("Oct" <> unparsed), do: { 10, unparsed }
    defp month_to_integer("Nov" <> unparsed), do: { 11, unparsed }
    defp month_to_integer("Dec" <> unparsed), do: { 12, unparsed }
    defp month_to_integer(_), do: :error

    defp short_weekday_to_integer("Mon" <> unparsed), do: { 1, unparsed }
    defp short_weekday_to_integer("Tue" <> unparsed), do: { 2, unparsed }
    defp short_weekday_to_integer("Wed" <> unparsed), do: { 3, unparsed }
    defp short_weekday_to_integer("Thu" <> unparsed), do: { 4, unparsed }
    defp short_weekday_to_integer("Fri" <> unparsed), do: { 5, unparsed }
    defp short_weekday_to_integer("Sat" <> unparsed), do: { 6, unparsed }
    defp short_weekday_to_integer("Sun" <> unparsed), do: { 7, unparsed }
    defp short_weekday_to_integer(_), do: :error

    defp weekday_to_integer("Monday" <> unparsed), do: { 1, unparsed }
    defp weekday_to_integer("Tuesday" <> unparsed), do: { 2, unparsed }
    defp weekday_to_integer("Wednesday" <> unparsed), do: { 3, unparsed }
    defp weekday_to_integer("Thursday" <> unparsed), do: { 4, unparsed }
    defp weekday_to_integer("Friday" <> unparsed), do: { 5, unparsed }
    defp weekday_to_integer("Saturday" <> unparsed), do: { 6, unparsed }
    defp weekday_to_integer("Sunday" <> unparsed), do: { 7, unparsed }
    defp weekday_to_integer(_), do: :error

    defp pow10(2), do: 100
    defp pow10(4), do: 10000

    defp new(format, weekday, day, month, year, hour, minute, second, calendar, base_year) when format in [:imf_fixdate, :asctime] and is_binary(weekday) do
        case short_weekday_to_integer(weekday) do
            { weekday, "" } -> new(format, weekday, day, month, year, hour, minute, second, calendar, base_year)
            _ -> { :error, { format, :weekday } }
        end
    end
    defp new(format = :rfc850, weekday, day, month, year, hour, minute, second, calendar, base_year) when is_binary(weekday) do
        case weekday_to_integer(weekday) do
            { weekday, "" } -> new(format, weekday, day, month, year, hour, minute, second, calendar, base_year)
            _ -> { :error, { format, :weekday } }
        end
    end
    defp new(format = :asctime, weekday, " " <> day, month, year, hour, minute, second, calendar, base_year) do
        new(format, weekday, day, month, year, hour, minute, second, calendar, base_year)
    end
    defp new(format, weekday, day, month, year, hour, minute, second, calendar, base_year) do
        factor = pow10(String.length(year))
        with { :day, { day, "" } } <- { :day, Integer.parse(day) },
             { :month, { month, "" } } <- { :month, month_to_integer(month) },
             { :year, { year, "" } } <- { :year, Integer.parse(year) },
             { :hour, { hour, "" } } <- { :hour, Integer.parse(hour) },
             { :minute, { minute, "" } } <- { :minute, Integer.parse(minute) },
             { :second, { second, "" } } <- { :second, Integer.parse(second) } do
                date = %DateTime{
                    calendar: calendar,
                    day: day,
                    month: month,
                    year: div(base_year || DateTime.utc_now.year, factor) * factor + year,
                    hour: hour,
                    minute: minute,
                    second: second,
                    microsecond: { 0, 0 },
                    time_zone: "Etc/UTC",
                    zone_abbr: "UTC",
                    std_offset: 0,
                    utc_offset: 0
                }

                { :ok, { date, weekday } }
        else
            { type, _ } -> { :error, { format, type } }
        end
    end

    @doc false
    def parse_date(<<
        weekday :: binary-size(3),
        ", ",
        day :: binary-size(2),
        " ",
        month :: binary-size(3),
        " ",
        year :: binary-size(4),
        " ",
        hour :: binary-size(2),
        ":",
        minute :: binary-size(2),
        ":",
        second :: binary-size(2),
        " GMT"
    >>, calendar, base_year), do: new(:imf_fixdate, weekday, day, month, year, hour, minute, second, calendar, base_year)
    def parse_date(<<
        weekday :: binary-size(3),
        " ",
        month :: binary-size(3),
        " ",
        day :: binary-size(2),
        " ",
        hour :: binary-size(2),
        ":",
        minute :: binary-size(2),
        ":",
        second :: binary-size(2),
        " ",
        year :: binary-size(4)
    >>, calendar, base_year), do: new(:asctime, weekday, day, month, year, hour, minute, second, calendar, base_year)
    def parse_date(date, calendar, base_year) do
        case weekday_to_integer(date) do
            {
                weekday,
                <<
                    ", ",
                    day :: binary-size(2),
                    "-",
                    month :: binary-size(3),
                    "-",
                    year :: binary-size(2),
                    " ",
                    hour :: binary-size(2),
                    ":",
                    minute :: binary-size(2),
                    ":",
                    second :: binary-size(2),
                    " GMT"
                >>
            } -> new(:rfc850, weekday, day, month, year, hour, minute, second, calendar, base_year)
            _ -> { :error, :unknown_format }
        end
    end
end
