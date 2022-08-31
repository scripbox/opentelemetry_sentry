# OpentelemetrySentry

This library provides support for propagating `sentry-trace` http
header. This would make it possible to use distributed tracing feature
of sentry. More details about the setup can be found in the [blog post](https://ananthakumaran.in/2022/06/11/sentry-performance-monitoring-for-elixir.html)


```elixir
def deps do
  [
    {:opentelemetry_sentry, "~> 0.1.0"}
  ]
end
```

```elixir
config :opentelemetry,
  text_map_propagators: [OpentelemetrySentry.Propagator]
```
