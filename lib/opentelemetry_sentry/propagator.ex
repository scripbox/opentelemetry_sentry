defmodule OpentelemetrySentry.Propagator do
  require OpenTelemetry.Tracer, as: Tracer

  @behaviour :otel_propagator_text_map
  require Record
  @fields Record.extract(:span_ctx, from_lib: "opentelemetry_api/include/opentelemetry.hrl")
  Record.defrecordp(:span_ctx, @fields)
  @header_key "sentry-trace"

  def fields(_) do
    [@header_key]
  end

  def inject(ctx, carrier, carrier_set, _options) do
    case Tracer.current_span_ctx(ctx) do
      span_ctx = span_ctx(trace_id: trace_id, span_id: span_id)
      when trace_id != 0 and span_id != 0 ->
        sentry_trace = encode(span_ctx)
        carrier_set.(@header_key, sentry_trace, carrier)

      _ ->
        carrier
    end
  end

  def extract(ctx, carrier, _carrier_keys_fun, carrier_get, _options) do
    maybe_trace_string = carrier_get.(@header_key, carrier)

    case maybe_trace_string do
      :undefined ->
        ctx

      trace_string ->
        case decode(trace_string) do
          :undefined ->
            ctx

          span_ctx ->
            Tracer.set_current_span(ctx, span_ctx)
        end
    end
  end

  # https://develop.sentry.dev/sdk/performance/#header-sentry-trace
  defp decode(
         <<trace_id::binary-size(32), "-", span_id::binary-size(16), "-",
           sampled::binary-size(1)>>
       ) do
    to_span_ctx(trace_id, span_id, sampled)
  end

  defp decode(<<trace_id::binary-size(32), "-", span_id::binary-size(16)>>) do
    to_span_ctx(trace_id, span_id, "0")
  end

  defp decode(_), do: :undefined

  defp encode(span_ctx(trace_id: trace_id, span_id: span_id, trace_flags: trace_flags)) do
    sampled =
      if Bitwise.band(trace_flags, 1) == 1 do
        "1"
      else
        "0"
      end

    Enum.join(
      [
        :io_lib.format("~32.16.0b", [trace_id]),
        :io_lib.format("~16.16.0b", [span_id]),
        sampled
      ],
      "-"
    )
  end

  defp to_span_ctx(trace_id_string, span_id_string, sampled) when sampled in ["0", "1"] do
    trace_flags =
      case sampled do
        "1" -> 1
        "0" -> 0
      end

    with {trace_id, ""} <- Integer.parse(trace_id_string, 16),
         {span_id, ""} <- Integer.parse(span_id_string, 16) do
      :otel_tracer.from_remote_span(trace_id, span_id, trace_flags)
    else
      _ ->
        :undefined
    end
  end

  defp to_span_ctx(_, _, _), do: :undefined
end
