defmodule PDB.Types do
  @moduledoc """
  Allows type indexes to be mapped to specific types.
  """

  @map %{
    0x0000  => :none,
    0x0003  => :void,
    0x0007  => :not_translated,
    0x0008  => :hresult
  }
end
