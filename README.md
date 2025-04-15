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
- `F.bind(func, ...)`
- `F.id(...)`
- `F.index(ix)`
- `F.index_into(obj)`
- `F.foreach(obj, func, f_pairs)`
- `F.merge(a, b, f_pairs_a, f_pairs_b)`
- `F.concat(a, b, f_ipairs_a, f_ipairs_b)`
- `F.keys(table, f_pairs)`
- `F.values(table, f_pairs)`
- `F.entries(table, f_pairs)`

# Fluent mode

Defines syntax for fluent queries:
- `F.pairs(obj)`
- `F.ipairs(obj)`
- `F.from(obj, f_pairs, numeric)`
- `F.from_range(start, _end, step)`
- `F.q_concat(a, b)`
- `q:map(func)`
- `q:filter(func)`
- `q:flatmap(func)`
- `q:take(n)`
- `q:skip(n)`
- `q:keys()`
- `q:values()`
- `q:entries()`
- `q:sorted(func)`
- `q:append(other)`
- `q:prepend(other)`
- `q:join(other, func)`
- `q:zip(other, func)`
- `q:foreach(func)`
- `q:reduce(seed, func)`
- `q:count(func)`
- `q:conjoin(separator)`
- `q:tostring()`
- `q:into()`
- `q:pairs()`
- `q:any()`
- `q:all()`
- `q:unordered()`
- `q:ordered()`
- `q.next()`
- `q.numeric`

# Example usage

```lua
for k, v in 
    F.from_range(1, 10) -- Query the integers from 1 to 10
    :map(function(x) return x * x end) -- Square them
    :filter(function(x) return x >= 20 end) -- Discard any squares less than 20
    :pairs() -- Iterate over the query
do
    print(k, v)
end

local things = {
    c = 3,
    b = 2,
    a = 1,
    d = 4
}
-- `stuff` is a list of the keys of `things` sorted by their respective values
local stuff = F.pairs(things) -- Query `things`
    :sorted(function(a, b) return a < b end) -- Sort the query with the given function
    :entries() -- Start working on key-value pairs
    :map(F.index(1)) -- Select the keys from those key-value pairs (`:map(F.index('k'))` would do the same)
    :into() -- Turn the result into a table
for _, v in ipairs(stuff) do
    print(v)
end
```
