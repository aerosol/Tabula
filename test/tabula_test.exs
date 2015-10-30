defmodule TabulaTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @rows  [%{"name" => "Adam", "age" => 32, "city" => "Warsaw"},
          %{"name" => "Yolanda", "age" => 28, "city" => "New York"}]

  @cols ["name", "age", "city"]

  test "Calculate max widths properly" do
    assert Tabula.max_widths(@cols, @rows) == [7, 3, 8]
  end

  test "Columns can be provided by the user or discovered automatically" do
    auto = fn ->
      Tabula.print_table @rows
    end
    man = fn ->
      Tabula.print_table @rows, only: Enum.sort(@cols)
    end
    assert capture_io(auto) == capture_io(man)
  end

  test "Special column '#' can be provided to enumerate rows" do
    table = fn ->
      Tabula.print_table(@rows, only: ["#"|@cols])
    end
    expect = """
      # | name    | age | city    
    ----+---------+-----+---------
      1 | Adam    |  32 | Warsaw  
      2 | Yolanda |  28 | New York

    """
    assert capture_io(table) == expect
  end

  test "Github Markdown style can be applied" do
    table = fn ->
      Tabula.print_table(@rows, only: Enum.sort(@cols), style: :github_md)
    end
    expect = """
    age | city     | name   
    --- | -------- | -------
     32 | Warsaw   | Adam   
     28 | New York | Yolanda

    """
    assert capture_io(table) == expect
  end

  test "Columns not found are represented by `nil`" do
    table = fn ->
      Tabula.print_table(@rows, only: ["phone", "email"])
    end
    expect = """
    phone | email
    ------+------
    nil   | nil  
    nil   | nil  

    """
    assert capture_io(table) == expect
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
  end

  test "Options will be merged" do
    defmodule Bar do
      use Tabula, style: :github_md

      @data [%{"hello" => "world", "cruel" => true}]

      def t1 do
        @data |> print_table
      end
      def t2 do
        @data |> print_table(only: ["cruel"])
      end
      def t3 do
        @data |> print_table(only: ["#", "cruel"], style: :org_mode)
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

    assert capture_io(&Bar.t1/0) == e1
    assert capture_io(&Bar.t2/0) == e2
    assert capture_io(&Bar.t3/0) == e3
  end

  test "Long auto-indices will be aligned properly" do
    l = String.length("10000")
    rows = 1..10000
           |> Enum.map(&(%{"index" => &1}))
    widths = Tabula.max_widths(["#", "index"], rows)
    assert widths == [l, l]
  end

end
