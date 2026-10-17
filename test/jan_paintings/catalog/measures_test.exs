defmodule JanPaintings.Catalog.MeasuresTest do
  use ExUnit.Case, async: true

  import JanPaintings.Catalog.Measures

  doctest JanPaintings.Catalog.Measures

  describe "parse_price/1" do
    test "reads the amount and currency, ignoring words around them" do
      assert parse_price("$1,500 USD") == {1500, "USD"}
      assert parse_price("Framed $950 CAD") == {950, "CAD"}
      assert parse_price("The set $12,000 USD, framed") == {12000, "USD"}
      assert parse_price("Each $750.00 usd") == {750, "USD"}
    end

    test "keeps the amount when no currency is given" do
      assert parse_price("$600") == {600, nil}
    end

    test "returns nils when there is no amount" do
      assert parse_price("On request") == {nil, nil}
      assert parse_price("") == {nil, nil}
      assert parse_price(nil) == {nil, nil}
      assert parse_price("CAD on request") == {nil, nil}
    end
  end

  describe "parse_size/1" do
    test "reads height and width in millimetres" do
      assert parse_size("206 × 160mm") == {206, 160}
      assert parse_size("504 × 350 mm") == {504, 350}
      assert parse_size("260 x356mm") == {260, 356}
      assert parse_size("Plate 120.6 X 88.4 mm") == {121, 88}
    end

    test "returns nils when there is no size" do
      assert parse_size("") == {nil, nil}
      assert parse_size(nil) == {nil, nil}
      assert parse_size("Large folio") == {nil, nil}
    end
  end

  test "normalize_size/1 writes sizes as H × Wmm and leaves other text alone" do
    assert normalize_size("260 x356mm") == "260 × 356mm"
    assert normalize_size("Plate 504 × 350 mm") == "Plate 504 × 350mm"
    assert normalize_size("206 × 160mm") == "206 × 160mm"
    assert normalize_size("Large folio") == "Large folio"
    assert normalize_size("") == ""
  end

  test "format_amount/1 adds thousands separators" do
    assert format_amount(375) == "375"
    assert format_amount(4000) == "4,000"
    assert format_amount(1_250_000) == "1,250,000"
  end
end
