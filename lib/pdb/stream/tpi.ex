defmodule PDB.Stream.TPI do
  @moduledoc """
  Represents the PDB TPI stream, at fixed index 2 within the PDB file.
  """
  alias __MODULE__
  defstruct [
    :version,
    :header_size,
    :type_index_begin,
    :type_index_end,
    :type_record_bytes,

    :hash_stream_index,
    :hash_aux_stream_index,
    :hash_key_size,
    :num_hash_buckets,

    :hash_value_buffer_offset,
    :hash_value_buffer_length,

    :index_offset_buffer_offset,
    :index_offset_buffer_length,

    :hash_adj_buffer_offset,
    :hash_adj_buffer_length
  ]

  @stream_id 2
  @versions %{
    19950410  => :v40,
    19951122  => :v41,
    19961031  => :v50,
    19990903  => :v70,
    20040203  => :v80
  }

  @doc """
  Deserialize the TPI stream from the given MSF file.
  """
  def deserialize(%MSFFormat{} = msf) do
    with  {:ok, stream} <- MSFFormat.open_stream(msf, @stream_id),
          {:ok, data}   <- MSFFormat.Stream.read_all(stream) do
      deserialize(%TPI{}, data)
    end
  end
  def deserialize(%TPI{version: nil} = tpi, <<
    version                     :: 32-little-unsigned,
    header_size                 :: 32-little-unsigned,
    type_index_begin            :: 32-little-unsigned,
    type_index_end              :: 32-little-unsigned,
    type_record_bytes           :: 32-little-unsigned,
    hash_stream_index           :: 16-little-unsigned,
    hash_aux_stream_index       :: 16-little-unsigned,
    hash_key_size               :: 32-little-unsigned,
    num_hash_buckets            :: 32-little-unsigned,
    hash_value_buffer_offset    :: 32-little,
    hash_value_buffer_length    :: 32-little-unsigned,
    index_offset_buffer_offset  :: 32-little,
    index_offset_buffer_length  :: 32-little-unsigned,
    hash_adj_buffer_offset      :: 32-little,
    hash_adj_buffer_length      :: 32-little-unsigned,
    rest                        :: binary
  >>) do
    deserialize(%{tpi |
      version:                    Map.get(@versions, version, :unknown),
      header_size:                header_size,
      type_index_begin:           type_index_begin,
      type_index_end:             type_index_end,
      type_record_bytes:          type_record_bytes,
      hash_stream_index:          hash_stream_index,
      hash_aux_stream_index:      hash_aux_stream_index,
      hash_key_size:              hash_key_size,
      num_hash_buckets:           num_hash_buckets,
      hash_value_buffer_offset:   hash_value_buffer_offset,
      hash_value_buffer_length:   hash_value_buffer_length,
      index_offset_buffer_offset: index_offset_buffer_offset,
      index_offset_buffer_length: index_offset_buffer_length,
      hash_adj_buffer_offset:     hash_adj_buffer_offset,
      hash_adj_buffer_length:     hash_adj_buffer_length
    }, type_index_end - type_index_begin, rest)
  end
  def deserialize(%TPI{} = tpi, 0, _data),
    do: {:ok, tpi}
  def deserialize(%TPI{} = tpi, record_count, data) do

  end
end
