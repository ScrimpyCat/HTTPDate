defmodule HTTPDate do
    @type format :: :imf_fixdate | :asctime | :rfc850
    @type component :: :day | :month | :year | :hour | :minute | :second

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

    @doc """
      Parse an HTTP-date (RFC 7231).

      This supports both the preferred format:
        Sun, 06 Nov 1994 08:49:37 GMT    ; IMF-fixdate

      As well as the obsolete formats:
        Sunday, 06-Nov-94 08:49:37 GMT   ; obsolete RFC 850 format
        Sun Nov  6 08:49:37 1994         ; ANSI C's asctime() format

      By default the parsed date will be validated to ensure that it is correct. If this
      validation is not desired it can be disabled by passing `false` to the `:validate`
      option.

      By default it uses `Calendar.ISO`, however this can be changed by passing another
      calendar to the `:calendar` option.

      As the obsolete RFC 850 format only allowed for the last 2 year digits, it is
      assumed these digits belong to the current year. If a specific base year is
      desired, pass the year to the `:base_year` option.

        iex> HTTPDate.parse("Sun, 06 Nov 1994 08:49:37 GMT")
        { :ok, elem(DateTime.from_iso8601("1994-11-06 08:49:37Z"), 1) }

        iex> HTTPDate.parse("Sunday, 06-Nov-94 08:49:37 GMT", base_year: 1900)
        { :ok, elem(DateTime.from_iso8601("1994-11-06 08:49:37Z"), 1) }

        iex> HTTPDate.parse("Sun Nov  6 08:49:37 1994")
        { :ok, elem(DateTime.from_iso8601("1994-11-06 08:49:37Z"), 1) }

        iex> HTTPDate.parse("Mon, 06 Nov 1994 08:49:37 GMT")
        { :error, :invalid }

        iex> HTTPDate.parse("Mon, 06 Nov 1994 08:49:37 GMT", validate: false)
        { :ok, elem(DateTime.from_iso8601("1994-11-06 08:49:37Z"), 1) }
    """
    @spec parse(String.t, Keyword.t) :: { :ok, DateTime.t } | { :error, :invalid | :unknown_format | { format, component } }
    def parse(date, opts \\ []) do
        calendar = opts[:calendar] || Calendar.ISO
        case { parse_date(date, calendar, opts[:base_year]), Keyword.get(opts, :validate, true) } do
            { { :ok, { date, weekday } }, true } ->
                cond do
                    not date.calendar.valid_date?(date.year, date.month, date.day) -> { :error, :invalid }
                    not date.calendar.valid_time?(date.hour, date.minute, date.second, date.microsecond) -> { :error, :invalid }
                    weekday != date.calendar.day_of_week(date.year, date.month, date.day) -> { :error, :invalid }
                    true -> { :ok, date }
                end
            { { :ok, { date, _ } }, _ } -> { :ok, date }
            { error, _ } -> error
        end
    end

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

    defp parse_date(<<
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
    defp parse_date(<<
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
    defp parse_date(date, calendar, base_year) do
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
