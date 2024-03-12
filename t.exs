defmodule StarknetExplorer.Calldata do

  def felt_to_int(<<"0x", hexa_value::binary>>) do
    {value, _} = Integer.parse(hexa_value, 16)
    value
  end

  def get_call_header_v1([to, selector, data_len | rest]) do
      data_length = felt_to_int(data_len)
      {calldata, rest} = Enum.split(rest, data_length)

      {%{
         :address => to,
         :selector => selector,
         :data_len => felt_to_int(data_len),
         :calldata => calldata
       }, rest}
  end

  def from_plain_calldata([array_len | rest], "0x1") do
      {calls, _} =
        List.foldl(
          Enum.to_list(1..felt_to_int(array_len)),
          {[], rest},
          fn _, {acc_current, acc_rest} ->
            {new, new_rest} = get_call_header_v1(acc_rest)
            {[new | acc_current], new_rest}
          end
        )

      Enum.reverse(calls)
  end

  def get_call_header_v0([to, selector, data_offset, data_len | rest]) do
    {%{
       :address => to,
       :selector => selector,
       :data_offset => felt_to_int(data_offset),
       :data_len => felt_to_int(data_len),
       :calldata => []
     }, rest}
  end

  def from_plain_calldata([array_len | rest], "0x0") do
    # Cutting down array_len because some old transactions may have weird calldata
    size = min(felt_to_int(array_len), length(rest))

    {calls, [_calldata_length | calldata]} =
      List.foldl(
        Enum.to_list(1..size),
        {[], rest},
        fn _, {acc_current, acc_rest} ->
          {new, new_rest} = get_call_header_v0(acc_rest)
          {[new | acc_current], new_rest}
        end
      )

    calls
    |> Enum.reverse()
    |> Enum.map(fn call ->
      %{call | :calldata => Enum.slice(calldata, call.data_offset, call.data_len)}
    end)
  end

  def from_plain_calldata_with_fallback(array, version) do
    try do
      calldata = StarknetExplorer.Calldata.from_plain_calldata(array, version)
      IO.inspect(calldata)
      calldata
    rescue
      exception ->
        calldata = case version do
          "0x0" -> StarknetExplorer.Calldata.from_plain_calldata(array, "0x1")
          "0x1" -> StarknetExplorer.Calldata.from_plain_calldata(array, "0x0")
          _ -> nil
        end
        IO.inspect(calldata)
        calldata
    end
  end
end

array = ["0x1", "0x41a78e741e5af2fec34b695679bc6891742439f7afb8484ecd7766661ad02bf",
"0x1987cbd17808b9a23693d4de7e246a443cfe37e6e7fbaeabd7d7e6532b07c3d", "0x0",
"0x5", "0x5",
"0x496a7832723e953233f7083200ffdd1ba78e4558838c00e974075bdfac4dbcc", "0x0",
"0x0", "0x1",
"0x3f5d40ec5847eb2b25e5221b050cbbde3e261628e8cc52fa2f3925ba9ac7dd6"]
# StarknetExplorer.Calldata.from_plain_calldata array, "0x0"
version = "0x0"
calldata = nil

calldata = StarknetExplorer.Calldata.from_plain_calldata_with_fallback(array, version)

IO.inspect calldata

defmodule JSONStringify do
  def stringify(data) when is_list(data) do
    "[" <> stringify_list(data) <> "]"
  end

  def stringify(data) when is_map(data) do
    "{" <> stringify_map(data) <> "}"
  end

  def stringify(data) when is_list(data) or is_map(data) do
    Enum.join(Enum.map(data, &stringify/1), ", ")
  end

  def stringify(data) when is_integer(data) or is_float(data) do
    :erlang.float_to_binary(data)
  end

  def stringify(data) when is_binary(data) do
    "\"" <> data <> "\""
  end

  defp stringify_list([]), do: ""
  defp stringify_list(list), do: Enum.join(Enum.map(list, &stringify/1), ", ")

  defp stringify_map(%{} = map) do
    Enum.join(Enum.map(Map.to_list(map), &stringify_map_entry/1), ", ")
  end

  defp stringify_map(%{}), do: ""

  defp stringify_map_entry({key, value}) do
    stringify(key) <> ": " <> stringify(value)
  end
end

a = [
%{
  address: "0x4806749db1148db91b18e9ef9e4698690b0f96289368378e84e51eaea73554",
  calldata: ["0xc6164da852d230360333d6ade3551ee3e48124c815704f51fa7f12d8287dcc",
   "0x11e1a300"],
  data_len: 2,
  data_offset: 4,
  selector: "0x5e70f5618a5819edcf5225f37d01485ed62110516ead9d1a51bfcf852f4264"
},
%{
  address: "0x4806749db1148db91b18e9ef9e4698690b0f96289368378e84e51eaea73554",
  calldata: ["0x7d83b422a5fee99afaca50b6adf7de759af4a725f61cce747e06b6c09f7ab38",
   "0x746a528800"],
  data_len: 2,
  data_offset: 6,
  selector: "0x5e70f5618a5819edcf5225f37d01485ed62110516ead9d1a51bfcf852f4264"
},
%{
  address: "0x4806749db1148db91b18e9ef9e4698690b0f96289368378e84e51eaea73554",
  calldata: ["0x1f3b27e2f13d7d86f7f4c7dceb267290f158ac383803b22b712f7f9e58905ef",
   "0x261dd1ce2f2088800000"],
  data_len: 2,
  data_offset: 8,
  selector: "0x5e70f5618a5819edcf5225f37d01485ed62110516ead9d1a51bfcf852f4264"
}
]
data = [
  %{
    name: "John",
    age: 30,
    hobbies: ["reading", "gaming"],
    address: %{
      street: "123 Main St",
      city: "New York"
    }
  },
  %{
    name: "Jane",
    age: 25,
    hobbies: ["painting", "traveling"],
    address: %{
      street: "456 Elm St",
      city: "San Francisco"
    }
  }
]
json_string = JSONStringify.stringify(data)
IO.inspect(json_string)
