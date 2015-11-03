defmodule Tabula do

  alias Tabula.Renderer

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
    cols = Renderer.extract_cols(rows, opts)
    Renderer.run(rows, cols, opts)
    |> :erlang.list_to_binary
  end

end
