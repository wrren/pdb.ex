defmodule PDB.HashTable do
  @moduledoc """
  The PDB file format includes a specification for a serialized hash table. This
  module exposes functions for reading and interrogating these tables.
  """
  alias __MODULE__
  defstruct [:size, :capacity, :present, :deleted, :entries]

  @doc """
  Deserialize a hash table from the given binary
  """
  def deserialize(<<size :: 32-little-unsigned, capacity :: 32-little-unsigned, rest :: binary>>),
    do: deserialize(%HashTable{size: size, capacity: capacity}, rest)
  def deserialize(_),
    do: {:error, :invalid_format}
  def deserialize(%HashTable{entries: entries, size: size} = table, rest) when length(entries) == size,
    do: {:ok, %{table | entries: Enum.reverse(entries)}, rest}
  def deserialize(%HashTable{present: nil} = table, <<count :: 32-little-unsigned, rest :: binary>>) do
    <<present :: binary-size(count)-unit(32), rest :: binary>> = rest
    deserialize(%{table | present: present}, rest)
  end
  def deserialize(%HashTable{deleted: nil} = table, <<count :: 32-little-unsigned, rest :: binary>>) do
    <<deleted :: binary-size(count)-unit(32), rest :: binary>> = rest
    deserialize(%{table | deleted: deleted, entries: []}, rest)
  end
  def deserialize(%HashTable{size: size, entries: entries} = table, <<key :: 32-little-unsigned, value :: 32-little-unsigned, rest :: binary>>)
    when length(entries) < size,
    do: deserialize(%{table | entries: [{key, value} | entries]}, rest)
  def deserialize(_, _),
    do: {:error, :invalid_format}

  @doc """
  Get a list of all present key-value pairs in the hash table.
  """
  def all(%HashTable{entries: entries}),
    do: entries

  @doc """
  Get the entry with the given get from the hash table.
  """
  def get(%HashTable{entries: entries}, key) do
    entries
    |> Enum.filter(fn {k, _v} -> k == key end)
    |> case do
      [{_key, value}] -> value
      _               -> nil
    end
  end
end
