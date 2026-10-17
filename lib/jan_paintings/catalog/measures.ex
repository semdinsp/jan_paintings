defmodule JanPaintings.Catalog.Measures do
  @moduledoc """
  Reads the sortable numbers out of a print's price and size text.

  The text Jan types stays what visitors see ("The set $4,000 USD",
  "Framed $950 CAD", "On request"); these functions pull out the amount,
  currency and dimensions so prints can be sorted by price or size.
  """

  @price ~r/\$\s*(\d[\d,]*)(?:\.\d+)?/
  @currency ~r/\b(USD|CAD)\b/i
  @size ~r/(\d+(?:\.\d+)?)\s*[x×]\s*(\d+(?:\.\d+)?)\s*mm/iu

  @doc """
  The amount (whole units) and currency in a price, each nil when absent.

      iex> parse_price("The set $4,000 USD")
      {4000, "USD"}
      iex> parse_price("On request")
      {nil, nil}
  """
  def parse_price(text) when is_binary(text) do
    amount =
      case Regex.run(@price, text) do
        [_, digits] -> digits |> String.replace(",", "") |> String.to_integer()
        nil -> nil
      end

    currency =
      case Regex.run(@currency, text) do
        [_, code] -> String.upcase(code)
        nil -> nil
      end

    {amount, if(amount, do: currency)}
  end

  def parse_price(_), do: {nil, nil}

  @doc """
  The height and width in whole millimetres, each nil when absent.

      iex> parse_size("260 x356mm")
      {260, 356}
  """
  def parse_size(text) when is_binary(text) do
    case Regex.run(@size, text) do
      [_, h, w] -> {to_mm(h), to_mm(w)}
      nil -> {nil, nil}
    end
  end

  def parse_size(_), do: {nil, nil}

  @doc """
  Writes a size in the catalogue's standard form, "H × Wmm", leaving any other
  words alone. Text without a recognisable size is returned unchanged.

      iex> normalize_size("504 × 350 mm")
      "504 × 350mm"
  """
  def normalize_size(text) when is_binary(text) do
    Regex.replace(@size, text, fn _, h, w -> "#{h} × #{w}mm" end, global: false)
  end

  def normalize_size(text), do: text

  @doc "An amount with thousands separators, e.g. 4000 → \"4,000\"."
  def format_amount(amount) when is_integer(amount) do
    amount
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  defp to_mm(value) do
    {number, _} = Float.parse(value)
    round(number)
  end
end
