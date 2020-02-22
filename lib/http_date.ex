defmodule HTTPDate do
    @type format :: :imf_fixdate | :asctime | :rfc850
    @type component :: :day | :month | :year | :hour | :minute | :second

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
        case { HTTPDate.Parser.parse_date(date, calendar, opts[:base_year]), Keyword.get(opts, :validate, true) } do
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
end
