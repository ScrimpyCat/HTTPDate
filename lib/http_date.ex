defmodule HTTPDate do
    @type format :: :imf_fixdate | :asctime | :rfc850
    @type component :: :day | :month | :year | :hour | :minute | :second

    defmodule ParseError do
        defexception [:type, :date, :calendar]

        @impl Exception
        def exception({ type, date, calendar }) do
            %ParseError{
                type: type,
                date: date,
                calendar: calendar
            }
        end

        defp readable_format(:imf_fixdate), do: "IMF-fixdate"
        defp readable_format(:asctime), do: "asctime"
        defp readable_format(:rfc850), do: "RFC 850"

        @impl Exception
        def message(%{ type: :invalid, date: date, calendar: calendar }), do: "invalid date for calendar (#{inspect calendar}): #{inspect date}"
        def message(%{ type: :unknown_format, date: date }), do: "unknown format: #{inspect date}"
        def message(%{ type: { format, component }, date: date }), do: "invalid #{component} component in #{readable_format(format)} format: #{inspect date}"
    end

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

    @doc """
      Parse an HTTP-date (RFC 7231).

      Raises a `HTTPDate.ParseError` if the date could not be parsed.

      For more details see `HTTPDate.parse/2`.

        iex> HTTPDate.parse!("Sun, 06 Nov 1994 08:49:37 GMT")
        elem(DateTime.from_iso8601("1994-11-06 08:49:37Z"), 1)
    """
    @spec parse!(String.t, Keyword.t) :: DateTime.t | no_return
    def parse!(date, opts \\ []) do
        case parse(date, opts) do
            { :ok, date } -> date
            { :error, type } -> raise ParseError, { type, date, opts[:calendar] || Calendar.ISO }
        end
    end

    @doc """
      Format as an HTTP-date (RFC 7231).

      By default it produces IMF-fixdate formatted dates, this can be changed by setting
      the `:format` option to the desired format, see `t:format/0`.

        iex> HTTPDate.format(HTTPDate.parse!("Sun, 06 Nov 1994 08:49:37 GMT"))
        "Sun, 06 Nov 1994 08:49:37 GMT"

        iex> HTTPDate.format(HTTPDate.parse!("Sunday, 06-Nov-94 08:49:37 GMT", base_year: 1900), format: :rfc850)
        "Sunday, 06-Nov-94 08:49:37 GMT"

        iex> HTTPDate.format(HTTPDate.parse!("Sun Nov  6 08:49:37 1994"), format: :asctime)
        "Sun Nov  6 08:49:37 1994"
    """
    @spec format(DateTime.t, Keyword.t) :: String.t
    def format(date, opts \\ []), do: HTTPDate.Formatter.format_date(date, opts[:format] || :imf_fixdate)
end
