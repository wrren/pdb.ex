defmodule PDBTest do
  use ExUnit.Case
  doctest PDB

  test "greets the world" do
    assert PDB.hello() == :world
  end
end
