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
