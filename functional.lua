---@author BakersDozenBagels <business@gdane.net>
---@copyright (c) 2025 BakersDozenBagels
---@license GPL-3.0
---@version 2.0.3

local f = {}
---@deprecated
f.lazy = {} -- Lazily-evaluated versions of the functions. The return values use metatables and so should not be serialized.
F = f -- export as global; change this line as desired

-- Polyfill Lua 5.2 behavior for `pairs` and `ipairs`.
local raw_pairs = pairs
pairs = function(t)
    local metatable = getmetatable(t)
    if metatable and metatable.__pairs then
        return metatable.__pairs(t)
    end
    return raw_pairs(t)
end
local raw_ipairs = ipairs
ipairs = function(t)
    local metatable = getmetatable(t)
    if metatable and metatable.__ipairs then
        return metatable.__ipairs(t)
    end
    return raw_ipairs(t)
end

-- "Polyfill" Lua 5.2 behavior for `#obj`.

--- Returns the number of keys in `obj`.
---@param obj table
function f.count(obj)
    local metatable = getmetatable(obj)
    if metatable and metatable.__len then
        return metatable.__len(obj)
    end
    return #obj
end

--- Generates a table like {4, 5, 6, 7}.
---@param min? integer The inclusive lower bound of the range. Defaults to `1`.
---@param max? integer The inclusive upper bound of the range. Defaults to `1`.
---@param step? integer The step between elements. Defaults to `1`.
function f.range(min, max, step)
    local ret = {}
    local ix = 1
    for i = min, max, step do
        ret[ix] = i
        ix = ix + 1
    end
    return ret
end

--- Performs a functional mapping.
---@param obj (table) The table to map over.
---@param func? (function(value, key) -> any) The mapping function. Defaults to `f.id`.
---@param f_pairs? pairs The method to iterate over `obj`. Defaults to `pairs`. 
function f.map(obj, func, f_pairs)
    func = func or f.id
    f_pairs = f_pairs or pairs
    local ret = {}
    for k, v in f_pairs(obj) do
        ret[k] = func(v, k)
    end
    return ret
end

--- Performs a functional reduction.
---@param obj (table) The table to reduce.
---@param seed? (any) The initial value for the accumulator. By default, uses the first value in `obj` (and skips reducing that index).
---@param func (function(accumulator, value, key) -> accumulator) The reduction function.
---@param f_ipairs? (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `ipairs`.
function f.reduce(obj, seed, func, f_ipairs)
    f_ipairs = f_ipairs or ipairs
    local ret = seed
    local it, table, first = f_ipairs(obj)
    if not ret then
        first, ret = it()
    end
    for k, v in it, table, first do
        ret = func(ret, v, k)
    end
    return ret
end

--- Returns `true` if and only if `func(obj[k])` is truthy for any `k`. Otherwise, returns false.
---@param obj (table) The table to reduce.
---@param func? (function(value, key) -> bool) The predicate function.
---@param f_pairs? (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `pairs`.
function f.any(obj, func, f_pairs)
    f_pairs = f_pairs or pairs
    for k, v in f_pairs(obj) do
        if not func or func(v, k) then
            return true
        end
    end
    return false
end

--- Returns `true` if and only if `func(obj[k])` is truthy for all `k`. Otherwise, returns false.
---@param obj (table) The table to reduce.
---@param func (function(value, key) -> bool) The predicate function.
---@param f_pairs? (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `pairs`.
function f.all(obj, func, f_pairs)
    f_pairs = f_pairs or pairs
    for k, v in f_pairs(obj) do
        if not func(v, k) then
            return false
        end
    end
    return true
end

--- Returns `true` if and only if `func(obj[k])` is falsy for all `k`. Otherwise, returns false.
---@param obj (table) The table to reduce.
---@param func? (function(value, key) -> bool) The predicate function.
---@param f_pairs? (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `pairs`.
function f.none(obj, func, f_pairs)
    f_pairs = f_pairs or pairs
    for k, v in f_pairs(obj) do
        if not func or func(v, k) then
            return false
        end
    end
    return true
end

--- Returns a new table with only the elements which pass a test.
---@param obj (table) The table to filter.
---@param func (function(value, key) -> bool) The predicate function.
---@param f_pairs? (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `pairs`.
function f.filter(obj, func, f_pairs)
    f_pairs = f_pairs or pairs
    local ret = {}
    for k, v in f_pairs(obj) do
        if func(v, k) then
            ret[k] = v
        end
    end
    return ret
end

--- Returns a new table with only the elements in the specified inclusive range. Elements are renumbered.
---@param obj (table) The table to filter.
---@param start? (integer) The inclusive minimum index. Defaults to `1`.
---@param _end? (integer) The inclusive maximum index. Defaults to infinity.
---@param f_ipairs? (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `ipairs`.
function f.slice(obj, start, _end, f_ipairs)
    f_ipairs = f_ipairs or ipairs
    start = start or 1
    local ret = {}
    local i = 1
    for k, v in f_ipairs(obj) do
        if i >= start and (not _end or i <= _end) then
            ret[k] = v
        end
    end
    return ret
end

--- Identity function over any number of inputs.
function f.id(...)
    return ...
end

--- Runs a function on every value in the table.
---@param obj (table) The table to use.
---@param func? (function(value, key) -> any) The function to run. Defaults to `f.id`.
---@param f_pairs? pairs The method to iterate over `obj`. Defaults to `pairs`. 
---@return The original table unchanged.
function f.foreach(obj, func, f_pairs)
    func = func or f.id
    f_pairs = f_pairs or pairs
    for k, v in f_pairs(obj) do
        func(v, k)
    end
    return obj
end

--- Merges two tables.
---@param a (table) The first table.
---@param b (table) The second table.
---@param f_pairs_a? pairs The method to iterate over `a`. Defaults to `pairs`.
---@param f_pairs_b? pairs The method to iterate over `b`. Defaults to `pairs`.
function f.merge(a, b, f_pairs_a, f_pairs_b)
    f_pairs_a = f_pairs_a or pairs
    f_pairs_b = f_pairs_b or pairs
    local ret = {}
    for k, v in f_pairs_a(a) do
        ret[k] = v
    end
    for k, v in f_pairs_b(b) do
        ret[k] = v
    end
    return ret
end

--- Concatenates two tables into a numerically-indexed table.
---@param a (table) The first table.
---@param b (table) The second table.
---@param f_ipairs_a? pairs The method to iterate over `a`. Defaults to `ipairs`.
---@param f_ipairs_b? pairs The method to iterate over `b`. Defaults to `ipairs`.
function f.concat(a, b, f_ipairs_a, f_ipairs_b)
    f_ipairs_a = f_ipairs_a or ipairs
    f_ipairs_b = f_ipairs_b or ipairs
    local ret = {}
    local i = 1
    for k, v in f_ipairs_a(a) do
        ret[i] = v
        i = i + 1
    end
    for k, v in f_ipairs_b(b) do
        ret[i] = v
        i = i + 1
    end
    return ret
end

--- Returns the keys of a table indexed numerically.
---@param table (table) The table.
---@param f_pairs? pairs The method to iterate over `table`. Defaults to `pairs`.
function f.keys(table, f_pairs)
    f_pairs = f_pairs or pairs
    local ret = {}
    for k in f_pairs(table) do
        ret[#ret + 1] = k
    end
    return ret
end

--- Returns the values of a table indexed numerically.
---@param table (table) The table.
---@param f_pairs? pairs The method to iterate over `table`. Defaults to `pairs`.
function f.values(table, f_pairs)
    f_pairs = f_pairs or pairs
    local ret = {}
    for _, v in f_pairs(table) do
        ret[#ret + 1] = v
    end
    return ret
end

--- Returns the key-value pairs of a table indexed numerically.
--- Each key-value pair is represented as `{ key, value, key=key, value=value }`.
---@param table (table) The table.
---@param f_pairs? pairs The method to iterate over `table`. Defaults to `pairs`.
function f.entries(table, f_pairs)
    f_pairs = f_pairs or pairs
    local ret = {}
    for k, v in f_pairs(table) do
        ret[#ret + 1] = {
            k,
            v,
            k = k,
            v = v,
            key = k,
            value = v
        }
    end
    return ret
end

--- Generates a table like {4, 5, 6, 7}.
---@param min? integer The inclusive lower bound of the range. Defaults to `1`.
---@param max? integer The inclusive upper bound of the range. Defaults to no upper bound.
---@param step? integer The step between elements. Defaults to `1`.
function f.lazy.range(min, max, step)
    min = min or 1
    step = step or 1

    local mt
    mt = {
        __ipairs = function(self)
            return mt.__ipairs_next, self, 0
        end,
        __ipairs_next = function(self, i)
            local v = min + i * step
            i = i + 1
            if v >= min and (not max or v <= max) then
                return i, v
            end
        end,
        __index = function(self, i)
            local v = min + (i - 1) * step
            return v >= min and (not max or v <= max) and v or nil
        end,
        __newindex = function(self, nk, nv)
            mt.__eager(self)
            self[nk] = nv
        end,
        __eager = function(self)
            setmetatable(self, nil)
            for k, v in mt.__ipairs(self) do
                self[k] = v
            end
        end,
        __len = function(self)
            return math.ceil((max - min + 1) / step)
        end
    }
    mt.__pairs = mt.__ipairs

    return setmetatable({}, mt)
end

--- Performs a functional mapping.
---@param obj (table) The table to map over.
---@param func? (function(value, key) -> any) The mapping function. Defaults to `f.id`.
---@param f_pairs? pairs The method to iterate over `obj`. Defaults to `pairs`. 
function f.lazy.map(obj, func, f_pairs)
    f_pairs = f_pairs or pairs

    local mt, f_next
    mt = {
        __pairs = function(self)
            return mt.__pairs_next, self, nil
        end,
        __pairs_next = function(self, i)
            if f_next == nil then
                local _
                f_next, _, i = f_pairs(obj)
            end
            local k, v = f_next(obj, i)
            if k ~= nil then
                return k, func(v, k)
            end
        end,
        __index = function(self, i)
            return func(obj[i], i)
        end,
        __newindex = function(self, nk, nv)
            mt.__eager(self)
            self[nk] = nv
        end,
        __eager = function(self)
            setmetatable(self, nil)
            for k, v in mt.__pairs(self) do
                self[k] = v
            end
        end,
        __len = function(self)
            return #obj
        end
    }

    return setmetatable({}, mt)
end

f.lazy.reduce = f.reduce
f.lazy.any = f.any
f.lazy.all = f.all
f.lazy.none = f.none

--- Returns a new table with only the elements which pass a test.
---@param obj (table) The table to filter.
---@param func (function(value, key) -> bool) The predicate function.
---@param f_pairs? (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `pairs`.
function f.lazy.filter(obj, func, f_pairs)
    f_pairs = f_pairs or pairs

    local mt, f_next
    mt = {
        __pairs = function(self)
            return mt.__pairs_next, self, nil
        end,
        __pairs_next = function(self, i)
            if f_next == nil then
                local _
                f_next, _, i = f_pairs(obj)
            end
            local k, v = f_next(obj, i)
            if k ~= nil then
                if not func(v, k) then
                    return mt.__pairs_next(self, k)
                else
                    return k, v
                end
            end
        end,
        __index = function(self, i)
            return func(obj[i], i) and obj[i] or nil
        end,
        __newindex = function(self, nk, nv)
            mt.__eager(self)
            self[nk] = nv
        end,
        __eager = function(self)
            setmetatable(self, nil)
            for k, v in mt.__pairs(self) do
                self[k] = v
            end
        end,
        __len = function(self)
            mt.__eager(self)
            return #self
        end
    }

    return setmetatable({}, mt)
end

--- Returns a new table with only the elements in the specified inclusive range. Elements are renumbered.
---@param obj (table) The table to filter.
---@param start? (integer) The inclusive minimum index. Defaults to `1`.
---@param _end? (integer) The inclusive maximum index. Defaults to infinity.
---@param f_ipairs? (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `ipairs`.
function f.slice(obj, start, _end, f_ipairs)
    f_ipairs = f_ipairs or pairs
    start = start or 1
    if _end then
        _end = _end - start + 1
    end

    local mt
    mt = {
        __ipairs = function(self)
            local ix
            local f_next, f_obj

            local function next(self, i)
                if f_next == nil then
                    f_next, f_obj, ix = f_ipairs(obj)
                    for i = 2, start do
                        ix = f_next(f_obj, ix)
                    end
                end
                i = i + 1
                if i <= _end then
                    local v
                    ix, v = f_next(f_obj, ix)
                    return i, v
                end
            end

            return next, self, 0
        end,
        __index = function(self, i)
            if i >= 1 and (not _end or i <= _end) then
                return obj[start + i - 1]
            end
        end,
        __newindex = function(self, nk, nv)
            mt.__eager(self)
            self[nk] = nv
        end,
        __eager = function(self)
            setmetatable(self, nil)
            for k, v in mt.__pairs(self) do
                self[k] = v
            end
        end,
        __len = function(self)
            return math.min(f.lazy.count(obj), _end or math.huge)
        end
    }
    mt.__pairs = mt.__ipairs

    return setmetatable({}, mt)
end

f.lazy.id = f.id
f.lazy.count = f.count
f.lazy.index = f.index

--- Eagerly runs a function on every value in the table.
---@param obj (table) The table to use.
---@param func? (function(value, key) -> any) The function to run. Defaults to `f.id`.
---@param f_pairs? pairs The method to iterate over `obj`. Defaults to `pairs`. 
---@return The original table unchanged.
function f.lazy.foreach(obj, func, f_pairs)
    func = func or f.id
    f_pairs = f_pairs or pairs
    for k, v in f_pairs(obj) do
        func(v, k)
    end
    return obj
end

--- Merges two tables.
---@param a (table) The first table.
---@param b (table) The second table.
---@param f_pairs_a? pairs The method to iterate over `a`. Defaults to `pairs`.
---@param f_pairs_b? pairs The method to iterate over `b`. Defaults to `pairs`.
function f.lazy.merge(a, b, f_pairs_a, f_pairs_b)
    error("Not implemented")
end

--- Concatenates two tables into a numerically-indexed table.
---@param a (table) The first table.
---@param b (table) The second table.
---@param f_ipairs_a? pairs The method to iterate over `a`. Defaults to `ipairs`.
---@param f_ipairs_b? pairs The method to iterate over `b`. Defaults to `ipairs`.
function f.lazy.concat(a, b, f_ipairs_a, f_ipairs_b)
    error("Not implemented")
end

--- Returns the keys of a table indexed numerically.
---@param table (table) The table.
---@param f_pairs? pairs The method to iterate over `table`. Defaults to `pairs`.
function f.lazy.keys(table, f_pairs)
    error("Not implemented")
end

--- Returns the values of a table indexed numerically.
---@param table (table) The table.
---@param f_pairs? pairs The method to iterate over `table`. Defaults to `pairs`.
function f.lazy.values(table, f_pairs)
    error("Not implemented")
end

--- Returns the key-value pairs of a table indexed numerically.
--- Each key-value pair is represented as `{ [1]=key, [2]=value, k=key, v=value }`.
---@param table (table) The table.
---@param f_pairs? pairs The method to iterate over `table`. Defaults to `pairs`.
function f.lazy.entries(table, f_pairs)
    error("Not implemented")
end

--- Eagerly evaluates a lazy sequence.
--- The sequence will no longer use a metatable.
---@param obj table
function f.lazy.to_eager(obj)
    local metatable = getmetatable(obj)
    if metatable and metatable.__eager then
        metatable.__eager(obj)
    end
    return obj
end

---@generic K, V
---@alias Next fun(self):K?, V?

---@class Query<K, V>: metatable
f._proto = {}

if false then
    --- Gets the next pair from this collection.
    ---@type Next
    function f._proto:next()
        return 1, 2
    end

    --- Indicates whether this collection is numerically-indexed.
    ---@type boolean
    f._proto.numeric = false
end

--- Maps elements from this collection to new ones.
---@generic K, V, U
---@param func fun(value: V, key: K): U
---@return Query<K, U>
function f._proto:map(func)
    return f._wrap(function()
        local k, v = self:next()
        if k == nil then
            return k, v
        end
        return k, func(v, k)
    end, self.numeric)
end

--- Maps elements from this collection to sequences of new ones.
---@generic K, V, U
---@param func fun(value: V, key: K): Query<K, U>
---@return Query<K, U>
function f._proto:flatmap(func)
    return self
        :map(func)
        :map(function(x) return (x.pairs and f.bind(x.pairs, x) or (self.numeric and f.ipairs or f.pairs))(x) end)
        :reduce(f.concat)
end

--- Performs a cross join on two queries.
---@generic K1, V1, K2, V2, U
---@param other Query<K2, V2>
---@param func fun(v1: V1, v2: V2, k1: K1, k2: K2): U
---@return Query<integer, U>
function f._proto:join(other, func)
    local ret = {}
    for k1, v1 in self:pairs() do
        for k2, v2 in other:pairs() do
            ret[#ret + 1] = func(v1, v2, k1, k2)
        end
    end
    return f.ipairs(ret)
end

--- Zips two queries together.
---@generic V1, V2, U
---@param other Query<integer, V2>
---@param func? fun(v1: V1, v2: V2, k: integer): U Default to `function(...) return {...} end`
---@return Query<integer, U>
function f._proto:zip(other, func)
    if not self.numeric or not other.numeric then error("Zipping is only supported on two numerically-indexed queries", 2) end
    func = func or function(...) return {...} end
    return f._wrap(function()
        local k1, v1 = self:next()
        local k2, v2 = other:next()
        if k1 == nil or k2 == nil then
            return
        end
        if k1 ~= k2 then error("Keys are mismatched") end
        return k1, func(v1, v2, k1)
    end, true)
end

--- Reduces the collection to a single element. The seed is optional.
---@generic K, V, A
---@param seed A|fun(a: A, b: V, k: K): A
---@param func? fun(a: A, b: V, k: K): A
---@return A
function f._proto:reduce(seed, func)
    local k, v
    if type(func) == 'nil' then
        func = seed
        k, seed = self:next()
        if k == nil then
            return seed
        end
    end
    while true do
        k, v = self:next()
        if k == nil then
            return seed
        end
        seed = func(seed, v, k)
    end
end

--- Returns the first truthy element, or false if none exist.
---@return boolean
function f._proto:any()
    for _, v in self:pairs() do
        if v then
            return v
        end
    end
    return false
end

--- Returns the first falsy element, or true if none exist.
---@return boolean
function f._proto:all()
    for _, v in self:pairs() do
        if not v then
            return v
        end
    end
    return true
end

--- Count the number of entries in the sequence, optionally filtered by a function.
---@generic K, V
---@param func? fun(v: V, k: K):boolean
---@return integer
function f._proto:count(func)
    local o = self
    if func then o = o:filter(func) end
    return o:reduce(0, function(x) return x + 1 end)
end

--- Filters elements in the collection to only those that match a given predicate.
--- This will renumber the keys of a numerically-indexed collection.
---@generic K, V
---@param func fun(value: V, key: K): boolean
---@return Query<K, V>
function f._proto:filter(func)
    if not func then
        error("Expected a filter function", 2)
    end
    local ix = 0
    return f._wrap(function()
        local k, v
        repeat
            k, v = self:next()
        until k == nil or func(v, k)
        if k == nil or not self.numeric then
            return k, v
        end
        ix = ix + 1
        return ix, v
    end, self.numeric)
end

--- Limits the query to the first n elements of the numerically-indexed collection.
---@param n integer
---@return Query
function f._proto:take(n)
    if not n or n < 0 then
        error("Expected non-negative number", 2)
    end
    if not self.numeric then
        error("Take is only supported for numerically-indexed tables", 2)
    end
    return f._wrap(function()
        n = n - 1
        if n >= 0 then
            return self:next()
        end
    end, true)
end

--- Skips the first n elements of the numerically-indexed collection.
---@param n integer
---@return Query
function f._proto:skip(n)
    if not self.numeric then
        error("Skip is only supported for numerically-indexed tables", 2)
    end
    for i = 1, n - 1 do
        self:next()
    end
    local ix = 0
    return f._wrap(function()
        ix = ix + 1
        local k, v = self:next()
        if k ~= nil then
            return ix, v
        end
    end, true)
end

--- Runs a function on every element in the collection in encounter order.
---@generic K, V
---@param func fun(value: V, key: K)
function f._proto:foreach(func)
    for k, v in self:pairs() do
        func(v, k)
    end
end

--- Appends another query to this one.
---@see f.q_concat
---@param other Query
---@return Query
function f._proto:prepend(other)
    return f.q_concat(other, self)
end

--- Appends this query to another.
---@see f.q_concat
---@param other Query
---@return Query
function f._proto:append(other)
    return f.q_concat(self, other)
end

--- Concatenates two queries.
--- If both are numerically-indexed, the result is as well, and keys will be renumbered.
--- Otherwise, the result will not be numerically-indexed, and keys will not be numbered.
---@param a Query
---@param b Query
---@return Query
function f.q_concat(a, b)
    local ix, swap = 0, false
    return f._wrap(function()
        ix = ix + 1
        local k, v = (swap and b or a):next()
        if k == nil and not swap then
            swap = true
            k, v = b:next()
        end
        if k ~= nil then
            return a.numeric and b.numeric and ix or k, v
        end
    end, a.numeric and b.numeric)
end

--- Returns a numerically-indexed query of this non-numerically-indexed query's keys.
---@generic K
---@return Query<integer, K>
function f._proto:keys()
    if self.numeric then
        error("Keys is not supported on numerically-indexed tables", 2)
    end
    local ix = 0
    return f._wrap(function()
        local k = self:next()
        if k ~= nil then
            ix = ix + 1
            return ix, k
        end
    end, true)
end

--- Returns a numerically-indexed query of this non-numerically-indexed query's values.
---@generic V
---@return Query<integer, V>
function f._proto:values()
    if self.numeric then
        error("Values is not supported on numerically-indexed tables", 2)
    end
    local ix = 0
    return f._wrap(function()
        local k, v = self:next()
        if k ~= nil then
            ix = ix + 1
            return ix, v
        end
    end, true)
end

--- Returns a numerically-indexed query of this query's key-value pairs.
---@generic K, V
---@return Query<integer, {[1]:K, [2]:V, k: K, v: V}>
function f._proto:entries()
    local ix = 0
    return f._wrap(function()
        local k, v = self:next()
        if k ~= nil then
            ix = ix + 1
            return ix, {
                k,
                v,
                k = k,
                v = v
            }
        end
    end, true)
end

--- Returns an identical query treated as non-numerically-indexed.
---@return Query
function f._proto:unordered()
    if not self.numeric then
        error("Unordered is only supported on numerically-indexed tables", 2)
    end
    return f._wrap(self.next, false)
end

--- Returns an identical query treated as numerically-indexed.
---@return Query
function f._proto:ordered()
    if self.numeric then
        error("Ordered is not supported on numerically-indexed tables", 2)
    end
    return f._wrap(self.next, true)
end

--- Brings this query into the supplied order.
---@generic K, V
---@param func fun(v1: V, v2: V, k1: K, k2: K): boolean Less than function
---@return Query<K, V>
function f._proto:sorted(func)
    local q = self.numeric and self:unordered() or self
    local t = q:entries():into()
    table.sort(t, function(a, b) return func(a.v, b.v, a.k, b.k) end)
    local ix = 0
    return f._wrap(function()
        ix = ix + 1
        local v = t[ix]
        if v then
            return v.k, v.v
        end
    end, true)
end

--- Joins the strings together with an optional separator.
---@param separator? string
---@return string
function f._proto:conjoin(separator)
    separator = separator or ''
    ---@type string
    return self:reduce(function(a, b) return tostring(a) .. separator .. tostring(b) end)
end

--- Converts the query to a string. Helpful for debugging.
---@return string
function f._proto:tostring()
    return '{ ' .. self:map(function(v, k)
        return '[' .. tostring(k) .. '] = ' .. tostring(v)
    end):reduce(function(a, b)
        return a .. ', ' .. b
    end) .. ' }'
end

--- Converts the query to a table.
---@return table
function f._proto:into()
    local ret = {}
    for k, v in self.next do
        ret[k] = v
    end
    return ret
end

--- Gets the iterator for this query.
---@generic K, V
---@return fun():K, V
function f._proto:pairs()
    return self.next
end

f._proto.ipairs = f._proto.pairs

--- Applies query methods to a function.
---@param func Next
---@param numeric boolean
---@return Query
function f._wrap(func, numeric)
    local val = {
        next = func,
        numeric = numeric
    }
    for k, v in pairs(f._proto) do
        val[k] = v
    end
    return val
end

--- Generic query factory.
--- @see f.pairs
--- @see f.ipairs
---@param obj table
---@param f_pairs fun(t: table):unknown
---@param numeric boolean
---@return Query
function f.from(obj, f_pairs, numeric)
    local next, t, k = f_pairs(obj)
    local v
    return f._wrap(function()
        k, v = next(t, k)
        return k, v
    end, numeric)
end

--- Creates a non-numerically-indexed query from the given table.
---@param obj table
---@return Query
function f.pairs(obj)
    return f.from(obj, pairs, false)
end

--- Creates a numerically-indexed query from the given table.
---@param obj table
---@return Query
function f.ipairs(obj)
    return f.from(obj, ipairs, true)
end

--- Creates a numerically-indexed query with the given range of numbers.
---@param start? integer
---@param _end? integer
---@param step? integer
---@return Query
function f.from_range(start, _end, step)
    start = start or 1
    _end = _end or 1
    step = step or 1
    local ix = 0
    return f._wrap(function()
        ix = ix + 1
        local ret = start + (ix - 1) * step
        if (_end > start and ret <= _end) or (_end < start and ret >= start) or (start == _end and ret == start) then
            return ix, ret
        end
    end, true)
end

--- Binds a function with certain parameters.
---@generic T
---@param func fun(...):T
---@param ... any
---@return fun(...):T
function f.bind(func, ...)
    local args = { ... }
    return function(...)
        local arg = { ... }
        for k, v in ipairs(args) do
            table.insert(arg, 1, v)
        end
        return func(unpack(arg))
    end
end

--- Returns x -> x[ix]
---@param ix any
---@return fun(any): any
function f.index(ix)
    return function(x)
        return x[ix]
    end
end

--- Returns x -> obj[x]
---@param obj any
---@return fun(any): any
function f.index_into(obj)
    return function(x)
        return obj[x]
    end
end

return f