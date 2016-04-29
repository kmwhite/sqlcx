defmodule Sqlcx.RowTest do
  use ExUnit.Case
  import Sqlcx.Row

  test "supports the YYYY-MM-DD HH:MM format" do
    [row] = from([:datetime],[:test],[{"1988-02-14 15:17"}], %{})
    assert %{test: {{1988,2,14},{15,17,0,0}}} == row
  end

  test "supports the YYYY-MM-DD HH:MM:SS format" do
    [row] = from([:datetime],[:test],[{"1988-02-14 15:17:11"}], %{})
    assert %{test: {{1988,2,14},{15,17,11,0}}} == row
  end

  test "supports the YYYY-MM-DD HH:MM:SS.FFF format" do
    [row] = from([:datetime],[:test],[{"1988-02-14 15:17:11.123"}], %{})
    assert %{test: {{1988,2,14},{15,17,11,123000}}} == row
  end

  test "supports the YYYY-MM-DD HH:MM:SS.FFFFFF format" do
    [row] = from([:datetime],[:test],[{"1988-02-14 15:17:11.123456"}], %{})
    assert %{test: {{1988,2,14},{15,17,11,123456}}} == row
  end
end
