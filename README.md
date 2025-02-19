# functional.lua

Defines `F`, a namespace for several list functions:
- `F.count(obj)`
- `F.range(min, max, step)`
- `F.map(obj, func, f_pairs)`
- `F.reduce(obj, seed, func, f_pairs)`
- `F.any(obj, func, f_pairs)`
- `F.all(obj, func, f_pairs)`
- `F.none(obj, func, f_pairs)`
- `F.filter(obj, func, f_pairs)`
- `F.slice(obj, start, _end, f_pairs)`
- `F.id(...)`
- `F.index(obj)`

# Lazy sequences

Additionally, `F.lazy` is defined with a nearly identical interface to `F` (changes listed below). Functions in `F.lazy` return *lazy sequences* instead of tables. Lazy sequences may be more performant than eager ones, but they cannot be serialized and deserialized, since they use metatables.

- `F.lazy.range` has `max` default to infinity instead of `1`.
- `F.lazy.to_eager(obj)` exists.