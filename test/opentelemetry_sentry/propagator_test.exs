defmodule OpentelemetrySentry.PropagatorTest do
  use ExUnit.Case
  require Record

  @fields Record.extract(:span_ctx, from_lib: "opentelemetry_api/include/opentelemetry.hrl")
  Record.defrecordp(:span_ctx, @fields)

  setup do
    :opentelemetry.set_text_map_propagator(
      :otel_propagator_text_map_composite.create([OpentelemetrySentry.Propagator])
    )
  end

  describe "extract" do
    test "valid" do
      run_extract([{"sentry-trace", "0000008c3defb1edb984fe2ac71c71c7-0007e5196e2ae38e-1"}])

      assert span_ctx(
               trace_id: 11_111_111_111_111_111_111_111_111_111_111,
               span_id: 2_222_222_222_222_222,
               trace_flags: 1
             ) = :otel_tracer.current_span_ctx()

      run_extract([{"sentry-trace", "0000008c3defb1edb984fe2ac71c71c7-0007e5196e2ae38e-0"}])

      assert span_ctx(
               trace_id: 11_111_111_111_111_111_111_111_111_111_111,
               span_id: 2_222_222_222_222_222,
               trace_flags: 0
             ) = :otel_tracer.current_span_ctx()

      run_extract([{"sentry-trace", "0000008c3defb1edb984fe2ac71c71c7-0007e5196e2ae38e"}])

      assert span_ctx(
               trace_id: 11_111_111_111_111_111_111_111_111_111_111,
               span_id: 2_222_222_222_222_222,
               trace_flags: 0
             ) = :otel_tracer.current_span_ctx()
    end

    test "invalid" do
      run_extract([{"sentry-trace", "hh00008c3defb1edb984fe2ac71c71c7-0007e5196e2ae38e"}])
      assert :undefined == :otel_tracer.current_span_ctx()

      run_extract([{"sentry-trace", "0000008c3defb1edb984fe2ac71c71c7-0007e5196e2ae38e-5"}])
      assert :undefined == :otel_tracer.current_span_ctx()

      run_extract([{"sentry-trace", "000000008c3defb1edb984fe2ac71c71c7-0007e5196e2ae38e-1"}])
      assert :undefined == :otel_tracer.current_span_ctx()

      run_extract([{"sentry-trace", "0000008c3defb1edb984fe2ac71c71c7-hh07e5196e2ae38e-1"}])
      assert :undefined == :otel_tracer.current_span_ctx()

      run_extract([{"sentry-trace", "0000008c3defb1edb984fe2ac71c71c7-000007e5196e2ae38e-1"}])
      assert :undefined == :otel_tracer.current_span_ctx()
    end
  end

  test "inject" do
    assert [] == :otel_propagator_text_map.inject([])

    :otel_tracer.set_current_span(
      span_ctx(
        trace_id: 11_111_111_111_111_111_111_111_111_111_111,
        span_id: 2_222_222_222_222_222,
        trace_flags: 1
      )
    )

    assert [{"sentry-trace", "0000008c3defb1edb984fe2ac71c71c7-0007e5196e2ae38e-1"}] ==
             :otel_propagator_text_map.inject([])

    :otel_tracer.set_current_span(
      span_ctx(
        trace_id: 11_111_111_111_111_111_111_111_111_111_111,
        span_id: 2_222_222_222_222_222,
        trace_flags: 0
      )
    )

    assert [{"sentry-trace", "0000008c3defb1edb984fe2ac71c71c7-0007e5196e2ae38e-0"}] ==
             :otel_propagator_text_map.inject([])
  end

  defp run_extract(headers) do
    :otel_ctx.clear()
    :otel_propagator_text_map.extract(headers)
  end
end
