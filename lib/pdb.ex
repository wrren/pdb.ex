defmodule PDB do
  @moduledoc """
  Provides functions for opening and reading Program Database (PDB) files.
  """
  defstruct [:pdb]

  def open(path) when is_binary(path) do
    with  {:ok, msf}        <- MSFFormat.open(path),
          {:ok, pdb_stream} <- PDB.Stream.PDB.deserialize(msf) do
      {:ok, %PDB{pdb: pdb_stream}}
    end
  end

  @doc """
  Get the stream index for the stream with the given name.
  """
  def get_stream(%PDB{pdb: stream}, name),
    do: PDB.Stream.PDB.get_stream(stream, name)

  @doc """
  Determine whether this PDB file contains an IPI stream.
  """
  def has_ipi_stream?(%PDB{pdb: stream}),
    do: PDB.Stream.PDB.has_flag?(stream, :vc110) or PDB.Stream.PDB.has_flag?(stream, :vc140)
end
