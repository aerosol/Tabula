defmodule Tabula.Renderer do

  import Enum, only: [
    concat: 2,
    intersperse: 2,
    join: 1,
    map: 2,
    max: 1,
    with_index: 1,
    zip: 2
  ]

  @index "#"

  @sheets \
  org_mode: [
    heading:        " | ",
    heading_border: "-+-",
    row:            " | ",
    spacer:         "-"
  ],
  github_md: [
    heading:        " | ",
    heading_border: " | ",
    row:            " | ",
    spacer:         "-"
  ]

  @default_sheet :org_mode

  def run(rows, [_|_]=cols, opts) do
    widths     = max_widths(cols, rows)
    formatters = widths |> formatters(opts)
    spacers    = widths |> spacers(opts)

    [ cols    |> render_row(:heading, formatters, opts),
      spacers |> render_row(:heading_border, formatters, opts),

      rows
      |> with_index
      |> map(fn indexed_row ->
              values(cols, indexed_row, opts)
              |> render_row(:row, formatters, opts)
             end) ]
  end

  def max_widths(cols, rows) do
    max_index = rows
    |> length
    |> strlen
    cols
    |> map(fn k ->
      max([
        strlen(k), max_index
        | map(rows, &(Map.get(&1, k) |> strlen))
      ])
    end)
  end

  def extract_cols([first|_]=_rows, opts) do
    case opts[:only] do
      nil ->
        first |> Map.keys
      cols when is_list(cols) ->
        cols
    end
  end

  defp render_row(cells, style_element, formatters, opts) do
    separator = style(style_element, opts)
    cells
    |> zip(formatters)
    |> map(fn {k, f} -> f.(k) end)
    |> intersperse(separator)
    |> concat('\n')
  end

  defp formatters(widths, _opts) do
    widths
    |> map(fn w ->
      fn (@index=cell) ->
           # need to rjust '#' orelse github fails to render
           String.rjust(cell, w)
         (cell) when is_binary(cell) ->
           String.ljust(cell, w)
         (cell) when is_number(cell) ->
           String.rjust(cell |> inspect, w)
         (cell) ->
           String.ljust(cell |> inspect, w)
      end
    end)
  end

  defp spacers(widths, opts) do
    map(widths, &(Stream.repeatedly(fn -> style(:spacer, opts) end))
                |> Stream.take(&1)
                |> join)
  end

  defp strlen(x) when is_binary(x), do: x |> String.length
  defp strlen(x), do: strlen(inspect x)

  defp values(cols, {row, index}, _opts) do
    cols
    |> map(fn (@index) -> index+1
              (col)    -> Map.get(row, col)
           end)
  end

  defp style(style, opts) do
    sheet = Keyword.get(opts, :style, @default_sheet)
    @sheets[sheet][style]
  end

end
