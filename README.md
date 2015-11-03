# Tabula

Tabula can transform a collection of maps (structs too, e.g.
[Ecto](https://github.com/elixir-lang/ecto) models)
into an ASCII/GitHub Markdown table.

It's a weekend-over-beer-project of mine, loosely based on
[clojure.pprint.print-table](http://git.io/vWz7T).

## Installation

  1. Add Tabula to your list of dependencies in mix.exs:

   ```elixir
   def deps do
       [{:tabula, "~> 2.0.1"}]
   end
   ```

  2. Ensure Tabula is started before your application:

   ```elixir
   def application do
      [applications: [:tabula]]
   end
   ```

Let's get down to business :beers:

## Examples

```elixir
defmodule Demo do

  use Tabula, style: :github_md

  def run do
    [ %{"name" => "Joe", "age" => 31, "city" => "New York"},
      %{"name" => "Adam", "age" => 33, "city" => "Warsaw"},
      %{"name" => "Yolanda", "age" => 28, "city" => "Berlin"}
    ] |> print_table
  end

end
```

`Demo.run` yields:

```
age | city     | name
--- | -------- | -------
 31 | New York | Joe
 33 | Warsaw   | Adam
 28 | Berlin   | Yolanda
```

Which renders in GitHub markdown as:

age | city     | name
--- | -------- | -------
 31 | New York | Joe
 33 | Warsaw   | Adam
 28 | Berlin   | Yolanda

Alternatively, you can use the default `:org_mode` style:

```elixir
defmodule Demo do

  def run do
    Code.get_docs(Atom, :docs) 
    |> Enum.sort
    |> Enum.map(fn {{function, arity}, _line, _kind, _signature, text} ->
      %{"function" => function,
        "arity"    => arity,
        "text"     => text |> String.split("\n") |> Enum.at(0) }
    end) |> Tabula.print_table
  end

end
```

So that `Demo.run` yields:

```
arity | function      | text
------+---------------+---------------------------------
    1 | :to_char_list | Converts an atom to a char list.
    1 | :to_string    | Converts an atom to a string.
```

You can specify the columns you want to render.
If you wish Tabula to automatically index your rows, you need to provide it with a special `#` key:

```
iex(1)> Repo.all(Account) |> Tabula.print_table(only: ["#", :name, :key])

  # | :name    | :key
----+----------+-----------------------------
  1 | Adam     | e1210f10a721485be4ad50604cda
  2 | Thomas   | c0ae1f149298ffded9f41a828cf5
```

You can use `render_table` to return an `iolist` of the rendered data,
if you wish not to write to stdout.

If in doubt, please consult the tests.

## MaybeFutureFeatures

If time permits I would like to implement the following extensions (contributions very much welcome!):

  - ANSI styles, because we all love colored output, don't we?
  - Custom formatters
  - Cell contents wrapping
  - Option to define max table width

## Authors

Adam Rutkowski - https://twitter.com/hq1aerosol
Adrian Gruntkowski - https://twitter.com/adrgrunt
