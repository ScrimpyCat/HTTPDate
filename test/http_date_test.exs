defmodule HTTPDateTest do
    use ExUnit.Case
    doctest HTTPDate

    describe "parsing" do
        test "IMF-fixdate" do
            assert { :ok, elem(DateTime.from_iso8601("2020-02-02 04:16:37Z"), 1) } == HTTPDate.parse("Sun, 02 Feb 2020 04:16:37 GMT")
            assert { :error, { :imf_fixdate, :day } } == HTTPDate.parse("Sun,  2 Feb 2020 04:16:37 GMT")
            assert { :ok, elem(DateTime.from_iso8601("2020-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Sun, 23 Feb 2020 04:16:37 GMT")
            assert { :ok, elem(DateTime.from_iso8601("2020-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Sun, 23 Feb 2020 04:16:37 GMT", base_year: 1900)
            assert { :ok, elem(DateTime.from_iso8601("2020-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Sun, 23 Feb 2020 04:16:37 GMT")
            assert { :error, :invalid } == HTTPDate.parse("Mon, 23 Feb 2020 04:16:37 GMT")
            assert { :ok, elem(DateTime.from_iso8601("2020-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Mon, 23 Feb 2020 04:16:37 GMT", validate: false)
            assert { :ok, elem(DateTime.from_iso8601("2020-02-28 04:16:37Z"), 1) } == HTTPDate.parse("Fri, 28 Feb 2020 04:16:37 GMT")
            assert { :ok, elem(DateTime.from_iso8601("2020-02-29 04:16:37Z"), 1) } == HTTPDate.parse("Sat, 29 Feb 2020 04:16:37 GMT")
            assert { :error, :invalid } == HTTPDate.parse("Sun, 30 Feb 2020 04:16:37 GMT")
            assert {
                :ok,
                %DateTime{
                    day: 30,
                    month: 2,
                    year: 2020,
                    hour: 4,
                    minute: 16,
                    second: 37,
                    time_zone: "Etc/UTC",
                    zone_abbr: "UTC",
                    std_offset: 0,
                    utc_offset: 0
                }
            } == HTTPDate.parse("Sun, 30 Feb 2020 04:16:37 GMT", validate: false)
            assert {
                :ok,
                %DateTime{
                    day: 30,
                    month: 2,
                    year: 122020,
                    hour: 4,
                    minute: 16,
                    second: 37,
                    time_zone: "Etc/UTC",
                    zone_abbr: "UTC",
                    std_offset: 0,
                    utc_offset: 0
                }
            } == HTTPDate.parse("Sun, 30 Feb 2020 04:16:37 GMT", base_year: 120000, validate: false)

            opts = [base_year: 1900, validate: false]
            assert { :error, { :imf_fixdate, :weekday } } == HTTPDate.parse("Foo, 06 Nov 1994 08:49:37 GMT", opts)
            assert { :error, { :imf_fixdate, :day } } == HTTPDate.parse("Sun, aa Nov 1994 08:49:37 GMT", opts)
            assert { :error, { :imf_fixdate, :month } } == HTTPDate.parse("Sun, 06 Foo 1994 08:49:37 GMT", opts)
            assert { :error, { :imf_fixdate, :year } } == HTTPDate.parse("Sun, 06 Nov aaaa 08:49:37 GMT", opts)
            assert { :error, { :imf_fixdate, :hour } } == HTTPDate.parse("Sun, 06 Nov 1994 aa:49:37 GMT", opts)
            assert { :error, { :imf_fixdate, :minute } } == HTTPDate.parse("Sun, 06 Nov 1994 08:aa:37 GMT", opts)
            assert { :error, { :imf_fixdate, :second } } == HTTPDate.parse("Sun, 06 Nov 1994 08:49:aa GMT", opts)
            assert { :error, :unknown_format } == HTTPDate.parse("Sun, 06 Nov 1994 08:49:37 aaa", opts)
            assert { :error, :unknown_format } == HTTPDate.parse("Sunday, 06 Nov 1994 08:49:37 GMT", opts)
            assert { :error, :unknown_format } == HTTPDate.parse("Sun, 06 Nov 94 08:49:37 GMT", opts)
        end

        test "RFC 850" do
            assert { :ok, elem(DateTime.from_iso8601("2020-02-02 04:16:37Z"), 1) } == HTTPDate.parse("Sunday, 02-Feb-20 04:16:37 GMT")
            assert { :error, { :rfc850, :day } } == HTTPDate.parse("Sunday,  2-Feb-20 04:16:37 GMT")
            assert { :ok, elem(DateTime.from_iso8601("2020-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Sunday, 23-Feb-20 04:16:37 GMT")
            assert { :ok, elem(DateTime.from_iso8601("1920-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Monday, 23-Feb-20 04:16:37 GMT", base_year: 1900)
            assert { :ok, elem(DateTime.from_iso8601("0020-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Sunday, 23-Feb-20 04:16:37 GMT", base_year: 0)
            assert { :ok, elem(DateTime.from_iso8601("2020-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Sunday, 23-Feb-20 04:16:37 GMT", base_year: 2000)
            assert { :error, :invalid } == HTTPDate.parse("Monday, 23-Feb-20 04:16:37 GMT", base_year: 2000)
            assert { :ok, elem(DateTime.from_iso8601("2020-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Monday, 23-Feb-20 04:16:37 GMT", base_year: 2000, validate: false)
            assert { :ok, elem(DateTime.from_iso8601("2020-02-28 04:16:37Z"), 1) } == HTTPDate.parse("Friday, 28-Feb-20 04:16:37 GMT", base_year: 2000)
            assert { :ok, elem(DateTime.from_iso8601("2020-02-29 04:16:37Z"), 1) } == HTTPDate.parse("Saturday, 29-Feb-20 04:16:37 GMT", base_year: 2000)
            assert { :error, :invalid } == HTTPDate.parse("Sunday, 30-Feb-20 04:16:37 GMT", base_year: 2000)
            assert {
                :ok,
                %DateTime{
                    day: 30,
                    month: 2,
                    year: 2020,
                    hour: 4,
                    minute: 16,
                    second: 37,
                    time_zone: "Etc/UTC",
                    zone_abbr: "UTC",
                    std_offset: 0,
                    utc_offset: 0
                }
            } == HTTPDate.parse("Sunday, 30-Feb-20 04:16:37 GMT", base_year: 2000, validate: false)
            assert {
                :ok,
                %DateTime{
                    day: 30,
                    month: 2,
                    year: 120020,
                    hour: 4,
                    minute: 16,
                    second: 37,
                    time_zone: "Etc/UTC",
                    zone_abbr: "UTC",
                    std_offset: 0,
                    utc_offset: 0
                }
            } == HTTPDate.parse("Sunday, 30-Feb-20 04:16:37 GMT", base_year: 120000, validate: false)

            opts = [base_year: 1900, validate: false]
            assert { :error, :unknown_format } == HTTPDate.parse("Foo, 06-Nov-94 08:49:37 GMT", opts)
            assert { :error, { :rfc850, :day } } == HTTPDate.parse("Sunday, aa-Nov-94 08:49:37 GMT", opts)
            assert { :error, { :rfc850, :month } } == HTTPDate.parse("Sunday, 06-Foo-94 08:49:37 GMT", opts)
            assert { :error, { :rfc850, :year } } == HTTPDate.parse("Sunday, 06-Nov-aa 08:49:37 GMT", opts)
            assert { :error, { :rfc850, :hour } } == HTTPDate.parse("Sunday, 06-Nov-94 aa:49:37 GMT", opts)
            assert { :error, { :rfc850, :minute } } == HTTPDate.parse("Sunday, 06-Nov-94 08:aa:37 GMT", opts)
            assert { :error, { :rfc850, :second } } == HTTPDate.parse("Sunday, 06-Nov-94 08:49:aa GMT", opts)
            assert { :error, :unknown_format } == HTTPDate.parse("Sunday, 06-Nov-94 08:49:37 aaa", opts)
            assert { :error, :unknown_format } == HTTPDate.parse("Sun, 06-Nov-94 08:49:37 GMT", opts)
            assert { :error, :unknown_format } == HTTPDate.parse("Sunday, 06-Nov-1994 08:49:37 GMT", opts)
        end

        test "asctime" do
            assert { :ok, elem(DateTime.from_iso8601("2020-02-02 04:16:37Z"), 1) } == HTTPDate.parse("Sun Feb 02 04:16:37 2020")
            assert { :ok, elem(DateTime.from_iso8601("2020-02-02 04:16:37Z"), 1) } == HTTPDate.parse("Sun Feb  2 04:16:37 2020")
            assert { :ok, elem(DateTime.from_iso8601("2020-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Sun Feb 23 04:16:37 2020")
            assert { :ok, elem(DateTime.from_iso8601("2020-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Sun Feb 23 04:16:37 2020", base_year: 1900)
            assert { :ok, elem(DateTime.from_iso8601("2020-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Sun Feb 23 04:16:37 2020")
            assert { :error, :invalid } == HTTPDate.parse("Mon Feb 23 04:16:37 2020")
            assert { :ok, elem(DateTime.from_iso8601("2020-02-23 04:16:37Z"), 1) } == HTTPDate.parse("Mon Feb 23 04:16:37 2020", validate: false)
            assert { :ok, elem(DateTime.from_iso8601("2020-02-28 04:16:37Z"), 1) } == HTTPDate.parse("Fri Feb 28 04:16:37 2020")
            assert { :ok, elem(DateTime.from_iso8601("2020-02-29 04:16:37Z"), 1) } == HTTPDate.parse("Sat Feb 29 04:16:37 2020")
            assert { :error, :invalid } == HTTPDate.parse("Sun Feb 30 04:16:37 2020")
            assert {
                :ok,
                %DateTime{
                    day: 30,
                    month: 2,
                    year: 2020,
                    hour: 4,
                    minute: 16,
                    second: 37,
                    time_zone: "Etc/UTC",
                    zone_abbr: "UTC",
                    std_offset: 0,
                    utc_offset: 0
                }
            } == HTTPDate.parse("Sun Feb 30 04:16:37 2020", validate: false)
            assert {
                :ok,
                %DateTime{
                    day: 30,
                    month: 2,
                    year: 122020,
                    hour: 4,
                    minute: 16,
                    second: 37,
                    time_zone: "Etc/UTC",
                    zone_abbr: "UTC",
                    std_offset: 0,
                    utc_offset: 0
                }
            } == HTTPDate.parse("Sun Feb 30 04:16:37 2020", base_year: 120000, validate: false)

            opts = [base_year: 1900, validate: false]
            assert { :error, { :asctime, :weekday } } == HTTPDate.parse("Foo Nov 06 08:49:37 1994", opts)
            assert { :error, { :asctime, :month } } == HTTPDate.parse("Sun Foo 06 08:49:37 1994", opts)
            assert { :error, { :asctime, :day } } == HTTPDate.parse("Sun Nov aa 08:49:37 1994", opts)
            assert { :error, { :asctime, :hour } } == HTTPDate.parse("Sun Nov 06 aa:49:37 1994", opts)
            assert { :error, { :asctime, :minute } } == HTTPDate.parse("Sun Nov 06 08:aa:37 1994", opts)
            assert { :error, { :asctime, :second } } == HTTPDate.parse("Sun Nov 06 08:49:aa 1994", opts)
            assert { :error, { :asctime, :year } } == HTTPDate.parse("Sun Nov 06 08:49:37 aaaa", opts)
            assert { :error, :unknown_format } == HTTPDate.parse("Sun Nov 06 08:49:37 94", opts)
            assert { :error, :unknown_format } == HTTPDate.parse("Sunday Nov 06 08:49:37 1994", opts)
        end
    end
end
