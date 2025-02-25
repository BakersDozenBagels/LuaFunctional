# functional.lua

Defines `F`, a namespace for several list functions:
- `F.count(obj)`
- `F.range(min, max, step)`
- `F.map(obj, func, f_pairs)`
- `F.reduce(obj, seed, func, f_ipairs)`
- `F.any(obj, func, f_pairs)`
- `F.all(obj, func, f_pairs)`
- `F.none(obj, func, f_pairs)`
- `F.filter(obj, func, f_pairs)`
- `F.slice(obj, start, _end, f_ipairs)`
- `F.id(...)`
- `F.index(obj)`
- `F.foreach(obj, func, f_pairs)`
- `f.merge(a, b, f_pairs_a, f_pairs_b)`
- `f.concat(a, b, f_ipairs_a, f_ipairs_b)`

# Lazy sequences

Additionally, `F.lazy` is defined with a nearly identical interface to `F` (changes listed below). Functions in `F.lazy` return *lazy sequences* instead of tables. Lazy sequences may be more performant than eager ones, but they cannot be serialized and deserialized, since they use metatables.

- `F.lazy.range` has `max` default to infinity instead of `1`.
- `F.lazy.to_eager(obj)` exists.

# Example usage

```lua
local list = F.lazy.range() -- 1..infinity
print(list[6]) -- 6
local squares = F.lazy.map(list, function(x) return x * x end)
print(squares[5]) -- 25
local has_eighty_one = F.any(squares, function(x) return x == 81 end)
print(has_eighty_one) -- true
```
