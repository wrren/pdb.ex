defmodule PDB.Stream.PDB do
  @moduledoc """
  Represents the PDB stream within a PDB file, along with functions to
  interpret and act on it.
  """
  alias PDB.{
    Stream,
    HashTable
  }
  defstruct [:version, :signature, :flags, :age, :guid, :stream_map, :num_keys, :keys, :features]

  # PDB Stream ID
  @stream_id 1

  @versions %{
    19941610 => :vc2,
    19950623 => :vc4,
    19950814 => :vc41,
    19960307 => :vc50,
    19970604 => :vc98,
    19990604 => :vc70dep,
    20000404 => :vc70,
    20030901 => :vc80,
    20091201 => :vc110,
    20140508 => :vc140
  }

  @doc """
  Attempt to deserialize a PDB stream from the given MSF file.
  """
  def deserialize(%MSFFormat{} = msf) do
    with  {:ok, stream} <- MSFFormat.open_stream(msf, @stream_id),
          {:ok, data}   <- MSFFormat.Stream.read_all(stream) do
      deserialize(data)
    end
  end
  def deserialize(<<
      version     :: 32-little-unsigned,
      signature   :: 32-little-unsigned,
      age         :: 32-little-unsigned,
      guid        :: 128,
      rest        :: binary
    >>),
    do: deserialize(%Stream.PDB{version: Map.get(@versions, version, :unknown), signature: signature, age: age, guid: guid}, rest)
  def deserialize(%Stream.PDB{num_keys: nil} = stream, <<num_keys :: 32-little-unsigned, rest :: binary>>),
    do: deserialize(%{stream | num_keys: num_keys}, rest)
  def deserialize(%Stream.PDB{num_keys: num_keys, keys: nil} = pdb, binary) do
    <<keys :: binary-size(num_keys), rest :: binary>> = binary
    with {:ok, table, rest} <- Symbol.PDB.HashTable.deserialize(rest) do
      deserialize(%{pdb | stream_map: table, keys: keys, flags: []}, rest)
    end
  end
  def deserialize(%Stream.PDB{flags: flags} = stream, <<20091201 :: 32-little-unsigned, rest :: binary>>),
    do: deserialize(%{stream | flags: [:vc110 | flags]}, rest)
  def deserialize(%Stream.PDB{flags: flags} = stream, <<20140508 :: 32-little-unsigned, rest :: binary>>),
    do: deserialize(%{stream | flags: [:vc140 | flags]}, rest)
  def deserialize(%Stream.PDB{flags: flags} = stream, <<0x4D544F4E :: 32-little-unsigned, rest :: binary>>),
    do: deserialize(%{stream | flags: [:no_type_merge | flags]}, rest)
  def deserialize(%Stream.PDB{flags: flags} = stream, <<0x494E494D :: 32-little-unsigned, rest :: binary>>),
    do: deserialize(%{stream | flags: [:minimal_debug_info | flags]}, rest)
  def deserialize(%Stream.PDB{} = stream, <<_flag :: 32-little-unsigned, rest :: binary>>),
    do: deserialize(stream, rest)
  def deserialize(%Stream.PDB{} = stream, binary) when byte_size(binary) == 0,
    do: {:ok, stream}

  @doc """
  Determine whether the PDB stream includes the given flag.
  """
  def has_flag?(%Stream.PDB{flags: flags}, flag) when is_atom(flag),
    do: Enum.member?(flags, flag)

  @doc """
  Get the stream index for the stream with the given name.
  """
  def get_stream(%Stream.PDB{stream_map: table} = pdb, name) do
    table
    |> HashTable.all()
    |> Enum.filter(fn {key, _value} -> stream_name(pdb, key) == name end)
    |> case do
      [{_key, value}] -> {:ok, value}
      []              -> {:error, :not_found}
    end
  end

  #
  # Given an offset into the stream name binary, retrieve the full stream name.
  #
  defp stream_name(%Stream.PDB{keys: keys}, offset) do
    <<_prefix :: size(offset)-binary, rest :: binary>> = keys
    stream_name(rest, [])
  end
  defp stream_name(<<0 :: 8>>, out),
    do: Enum.join(Enum.reverse(out))
  defp stream_name(<<char :: binary-size(1), rest :: binary>>, out),
    do: stream_name(rest, [char | out])
end
