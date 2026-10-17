defmodule JanPaintings.Repo.Migrations.AddSortFieldsToPrints do
  use Ecto.Migration

  # Numbers read from the price and size text, used to sort prints. The text
  # stays what visitors see. The parsing is copied here (not taken from
  # JanPaintings.Catalog.Measures) so this migration keeps working if that
  # module changes.

  @price ~r/\$\s*(\d[\d,]*)(?:\.\d+)?/
  @currency ~r/\b(USD|CAD)\b/i
  @size ~r/(\d+(?:\.\d+)?)\s*[x×]\s*(\d+(?:\.\d+)?)\s*mm/iu

  def up do
    alter table(:prints) do
      add :price_amount, :integer
      add :price_currency, :string
      add :height_mm, :integer
      add :width_mm, :integer
    end

    flush()

    %{rows: rows} = repo().query!("SELECT id, price, dimensions FROM prints")

    for [id, price, dimensions] <- rows do
      {amount, currency} = parse_price(price)
      {height, width} = parse_size(dimensions)

      repo().query!(
        """
        UPDATE prints
        SET price_amount = $2, price_currency = $3, height_mm = $4, width_mm = $5,
            dimensions = $6
        WHERE id = $1
        """,
        [id, amount, currency, height, width, normalize_size(dimensions)]
      )
    end
  end

  def down do
    alter table(:prints) do
      remove :price_amount
      remove :price_currency
      remove :height_mm
      remove :width_mm
    end
  end

  defp parse_price(text) do
    case Regex.run(@price, text) do
      [_, digits] ->
        currency =
          case Regex.run(@currency, text) do
            [_, code] -> String.upcase(code)
            nil -> nil
          end

        {digits |> String.replace(",", "") |> String.to_integer(), currency}

      nil ->
        {nil, nil}
    end
  end

  defp parse_size(text) do
    case Regex.run(@size, text) do
      [_, h, w] -> {to_mm(h), to_mm(w)}
      nil -> {nil, nil}
    end
  end

  defp normalize_size(text) do
    Regex.replace(@size, text, fn _, h, w -> "#{h} × #{w}mm" end, global: false)
  end

  defp to_mm(value) do
    {number, _} = Float.parse(value)
    round(number)
  end
end
