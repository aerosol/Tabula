defmodule TabulaTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  defmodule Point do
    defstruct [:x, :y]
  end

  @rows  [%{"name" => "Adam", "age" => 32, "city" => "Warsaw"},
          %{"name" => "Yolanda", "age" => 28, "city" => "New York"}]

  @cols ["name", "age", "city"]

  test "Calculate max widths properly" do
    assert Tabula.max_widths(@cols, @rows) == [7, 3, 8]
  end

  test "Columns can be provided by the user or discovered automatically" do
    auto = Tabula.render_table @rows
    man = Tabula.render_table @rows, only: Enum.sort(@cols)
    assert auto == man
  end

  test "Special column '#' can be provided to enumerate rows" do
    table = Tabula.render_table(@rows, only: ["#"|@cols])
    expect = """
      # | name    | age | city    
    ----+---------+-----+---------
      1 | Adam    |  32 | Warsaw  
      2 | Yolanda |  28 | New York
    """
    assert table == expect
  end

  test "Print function outputs valid table to stdout" do
    table = fn ->
      Tabula.print_table @rows
    end
    expect = """
    age | city     | name   
    ----+----------+--------
     32 | Warsaw   | Adam   
     28 | New York | Yolanda

    """
    assert capture_io(table) == expect
  end

  test "Github Markdown style can be applied" do
    table = Tabula.render_table(@rows, only: Enum.sort(@cols), style: :github_md)
    expect = """
    age | city     | name   
    --- | -------- | -------
     32 | Warsaw   | Adam   
     28 | New York | Yolanda
    """
    assert table == expect
  end

  test "Columns not found are represented by `nil`" do
    table = Tabula.render_table(@rows, only: ["phone", "email"])
    expect = """
    phone | email
    ------+------
    nil   | nil  
    nil   | nil  
    """
    assert table == expect
  end

  test "Crash when there are no columns provided" do
    catch_error Tabula.print_table([%{}])
    catch_error Tabula.print_table(@rows, only: [])
  end

  test "Modules can use Tabula for configuration" do
    defmodule Foo do
      use Tabula, style: :org_mode
    end
    assert Foo.__info__(:functions) |> Enum.member?({:print_table, 1})
    assert Foo.__info__(:functions) |> Enum.member?({:print_table, 2})
    assert Foo.__info__(:functions) |> Enum.member?({:render_table, 1})
    assert Foo.__info__(:functions) |> Enum.member?({:render_table, 2})
  end

  test "Options will be merged" do
    defmodule Bar do
      use Tabula, style: :github_md

      @data [%{"hello" => "world", "cruel" => true}]

      def t1 do
        @data |> render_table
      end
      def t2 do
        @data |> render_table(only: ["cruel"])
      end
      def t3 do
        @data |> render_table(only: ["#", "cruel"], style: :org_mode)
      end
    end

    e1 = """
    cruel | hello
    ----- | -----
    true  | world
    """

    e2 = """
    cruel
    -----
    true 
    """

    e3 = """
      # | cruel
    ----+------
      1 | true 
    """

    assert Bar.t1 == e1
    assert Bar.t2 == e2
    assert Bar.t3 == e3
  end

  test "Long auto-indices will be aligned properly" do
    l = String.length("10000")
    rows = 1..10000
           |> Enum.map(&(%{"index" => &1}))
    widths = Tabula.max_widths(["#", "index"], rows)
    assert widths == [l, l]
  end

  test "Uses string representation on structs, if available" do
    rows = [%{name: "ecto", version: Version.parse!("2.0.4"), point: %Point{x: 0, y: 0}},
            %{name: "phoenix", version: Version.parse!("1.2.0"), point: %Point{x: 1, y: 0}}]
    table = Tabula.render_table(rows)

    expect = """
    :name   | :point                        | :version
    --------+-------------------------------+---------
    ecto    | %TabulaTest.Point{x: 0, y: 0} | 2.0.4   
    phoenix | %TabulaTest.Point{x: 1, y: 0} | 1.2.0   
    """
    assert table == expect
  end

  test "Support keyword lists and preserve ordering of columns" do
    rows = [
      [name: "ecto", point: %Point{x: 0, y: 0}, version: Version.parse!("2.0.4")],
      [name: "phoenix", point: %Point{x: 1, y: 0}, version: Version.parse!("1.2.0")]
    ]
    table = Tabula.render_table(rows)

    expect = """
    :name   | :point                        | :version
    --------+-------------------------------+---------
    ecto    | %TabulaTest.Point{x: 0, y: 0} | 2.0.4   
    phoenix | %TabulaTest.Point{x: 1, y: 0} | 1.2.0   
    """
    assert table == expect
  end
end
