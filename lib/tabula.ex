defmodule Tabula do
  @moduledoc """
  Tabula can transform a list of maps (structs too, e.g. Ecto schemas) 
  or Keywords into an ASCII/GitHub Markdown table.
  """

  import Enum,
    only: [
      concat: 2,
      intersperse: 2,
      map: 2,
      max: 1,
      with_index: 1,
      zip: 2
    ]

  @index "#"
  @newline '\n'

  @sheets org_mode: [
            heading: " | ",
            heading_border: "-+-",
            row: " | ",
            spacer: "-"
          ],
          github_md: [
            heading: " | ",
            heading_border: " | ",
            row: " | ",
            spacer: "-"
          ]

  @default_sheet :org_mode

  defmacro __using__(opts) do
    quote do
      def print_table(rows) do
        unquote(__MODULE__).print_table(rows, unquote(opts))
      end

      def print_table(rows, override_opts) do
        unquote(__MODULE__).print_table(rows, Keyword.merge(unquote(opts), override_opts))
      end

      def render_table(rows) do
        unquote(__MODULE__).render_table(rows, unquote(opts))
      end

      def render_table(rows, override_opts) do
        unquote(__MODULE__).render_table(rows, Keyword.merge(unquote(opts), override_opts))
      end
    end
  end

  defprotocol Row do
    @fallback_to_any true
    def get(row, col, default \\ nil)
    def keys(row)
  end

  defimpl Row, for: Map do
    def get(row, col, default \\ nil), do: Map.get(row, col, default)
    def keys(row), do: Map.keys(row)
  end

  defimpl Row, for: List do
    def get(row, col, default \\ nil), do: Keyword.get(row, col, default)
    def keys(row), do: Keyword.keys(row)
  end

  defimpl Row, for: Any do
    def get(%{__struct__: _} = row, col, default \\ nil), do: Map.get(row, col, default)

    def keys(%{__struct__: _} = row) do
      row
      |> Map.from_struct()
      |> Map.keys()
    end
  end

  def print_table(rows, opts \\ []) do
    rows
    |> render_table(opts)
    |> IO.puts()
  end

  def render_table(rows, opts \\ []) do
    rows
    |> extract_cols(opts)
    |> render_table(rows, opts)
    |> :erlang.list_to_binary()
  end

  defp render_table([_ | _] = cols, rows, opts) do
    widths = max_widths(cols, rows)
    formatters = formatters(widths, opts)
    spacers = spacers(widths, opts)

    [
      render_row(cols, :heading, formatters, opts),
      render_row(spacers, :heading_border, formatters, opts),
      rows
      |> with_index()
      |> map(fn indexed_row ->
        cols
        |> values(indexed_row)
        |> render_row(:row, formatters, opts)
      end)
    ]
  end

  def max_widths(cols, rows) do
    max_index =
      rows
      |> length()
      |> strlen()

    map(cols, fn k ->
      max([
        strlen(k),
        max_index
        | map(rows, &strlen(Row.get(&1, k)))
      ])
    end)
  end

  defp extract_cols([first | _], opts) do
    case opts[:only] do
      cols when is_list(cols) -> cols
      nil -> Row.keys(first)
    end
  end

  defp render_row(cells, style_element, formatters, opts) do
    separator = style(style_element, opts)

    cells
    |> zip(formatters)
    |> map(fn {k, f} -> f.(k) end)
    |> intersperse(separator)
    |> concat(@newline)
  end

  defp render_cell(v) when is_binary(v), do: v
  defp render_cell(v) when is_number(v), do: inspect(v)

  defp render_cell(%{__struct__: _} = v) do
    if String.Chars.impl_for(v) do
      to_string(v)
    else
      inspect(v)
    end
  end

  defp render_cell(v), do: inspect(v)

  defp formatters(widths, _opts) do
    map(widths, fn w ->
      fn
        @index = cell ->
          # need to pad_leading '#' orelse github fails to render
          String.pad_leading(cell, w)

        cell when is_binary(cell) ->
          String.pad_trailing(cell, w)

        cell when is_number(cell) ->
          cell
          |> render_cell()
          |> String.pad_leading(w)

        cell ->
          cell
          |> render_cell()
          |> String.pad_trailing(w)
      end
    end)
  end

  defp spacers(widths, opts) do
    spacer = style(:spacer, opts)
    map(widths, &String.duplicate(spacer, &1))
  end

  defp strlen(x) do
    x
    |> render_cell
    |> String.length()
  end

  defp values(cols, {row, index}) do
    map(cols, fn
      @index -> index + 1
      col -> Row.get(row, col)
    end)
  end

  defp style(style, opts) do
    sheet = Keyword.get(opts, :style, @default_sheet)
    @sheets[sheet][style]
  end
end
