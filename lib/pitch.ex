defmodule Pitch do
  @reading_accent :reading_accent

  def setup do
    :ets.new(@reading_accent, [:named_table, :duplicate_bag])

    for [term, reading, accents] <- accents() do
      :ets.insert(@reading_accent, {{term, reading}, accents})
    end
  end

  def lookup(term, reading) do
    with [_ | _] = accents <- :ets.lookup(@reading_accent, {term, reading}) do
      Enum.map(accents, fn {_reading, positions} ->
        %{term: term, positions: positions, html: html(reading, positions)}
      end)
    end
  end

  def accents do
    accents = File.read!("priv/accents.txt")
    Pitch.Parser.parse_string(accents, skip_headers: true)
  end

  # "priv/🇯🇵 Vocabulary - JLPT5 RU.csv"
  # "priv/🇯🇵 Vocabulary - JLPT5への言葉.csv"

  def process(file) do
    iodata =
      File.read!(file)
      |> NimbleCSV.RFC4180.parse_string(skip_headers: true)
      |> Enum.map(fn [_ | [term | [reading | _rest]]] = row ->
        case lookup(term, reading) do
          [%{html: html}] -> List.insert_at(row, 3, html)
          [] -> row
        end
      end)
      |> Pitch.Parser.dump_to_iodata()

    file
    |> String.replace(Path.extname(file), ".tsv")
    |> File.write!(iodata)
  end

  def html(reading, positions) do
    positions = positions |> String.split(",") |> Enum.map(&String.to_integer/1)
    moras = moras(reading)

    spans =
      case positions do
        [0 | _] -> render_accentless(moras)
        [1 | _] -> render_on_first(moras)
        [n | _] -> render_on(moras, n)
      end

    Enum.join(spans)
  rescue
    _ -> nil
  end

  @border_b "border-bottom:1px solid rgba(190,242,100);"
  @border_t "border-top:1px solid rgba(190,242,100);"
  @border_r "border-right:1px solid rgba(190,242,100);"
  @border_l "border-left:1px solid rgba(190,242,100);"

  defp render_accentless([first | rest]) do
    [span(first, [@border_b, @border_r]) | spans(rest, @border_t)]
  end

  defp render_on_first([first | rest]) do
    [span(first, [@border_t, @border_r]) | spans(rest, @border_b)]
  end

  defp render_on(letters, n) do
    case Enum.split(letters, n) do
      {[first | high], [last | low]} ->
        List.flatten([
          span(first, [@border_b, @border_r]),
          spans(high, @border_t),
          span(last, [@border_l, @border_b]),
          spans(low, @border_b)
        ])

      {[first | high], []} ->
        {last, high} = List.pop_at(high, -1)

        List.flatten([
          span(first, [@border_b, @border_r]),
          spans(high, @border_t),
          span(last, [@border_t, @border_r])
        ])
    end
  end

  defp span(letter, class) do
    IO.iodata_to_binary(["<span style='padding:1px;", class, "'>", letter, "</span>"])
  end

  defp spans(letters, class) do
    Enum.map(letters, &span(&1, class))
  end

  defp moras(reading) do
    reading |> String.codepoints() |> combine_into_moras()
  end

  @yoon ["ゃ", "ゅ", "ょ"] ++ ["ャ", "ュ", "ョ", "ィ"]

  defp combine_into_moras([first | [second | rest]]) when second in @yoon do
    [first <> second | combine_into_moras(rest)]
  end

  defp combine_into_moras([mora | rest]) do
    [mora | combine_into_moras(rest)]
  end

  defp combine_into_moras([]), do: []
end
