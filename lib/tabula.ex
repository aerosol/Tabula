defmodule Tabula do
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

  defmacro __using__(opts) do
    quote do
      def print_table(rows) do
        unquote(__MODULE__).print_table(rows, unquote(opts))
      end
      def print_table(rows, override_opts) do
        unquote(__MODULE__).print_table(
          rows, Keyword.merge(unquote(opts), override_opts))
      end
      def render_table(rows) do
        unquote(__MODULE__).render_table(rows, unquote(opts))
      end
      def render_table(rows, override_opts) do
        unquote(__MODULE__).render_table(
          rows, Keyword.merge(unquote(opts), override_opts))
      end
    end
  end

  def print_table(rows, opts \\ []) do
    render_table(rows, opts)
    |> IO.puts
  end

  def render_table(rows, opts \\ []) do
    cols = extract_cols(rows, opts)
    _render_table(rows, cols, opts)
    |> :erlang.list_to_binary
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

  defp _render_table(rows, [_|_]=cols, opts) do
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

  defp extract_cols([first|_]=_rows, opts) do
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

  defp render_cell(v) when is_binary(v),
    do: v
  defp render_cell(v) when is_number(v),
    do: inspect(v)
  defp render_cell(%{__struct__: _} = v) do
    if String.Chars.impl_for(v) do
      to_string(v)
    else
      inspect(v)
    end
  end
  defp render_cell(v),
    do: inspect(v)

  defp formatters(widths, _opts) do
    map(widths, fn w ->
      fn @index=cell ->
           # need to rjust '#' orelse github fails to render
           String.rjust(cell, w)
         cell when is_binary(cell) ->
           String.ljust(cell, w)
         cell when is_number(cell) ->
           cell |> render_cell() |> String.rjust(w)
         cell ->
           cell |> render_cell() |> String.ljust(w)
      end
    end)
  end

  defp spacers(widths, opts) do
    map(widths, &(Stream.repeatedly(fn -> style(:spacer, opts) end))
                |> Stream.take(&1)
                |> join)
  end

  defp strlen(x), do: render_cell(x) |> String.length()

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
