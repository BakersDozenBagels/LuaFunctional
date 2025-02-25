---@author BakersDozenBagels <business@gdane.net>
---@copyright (c) 2025 BakersDozenBagels
---@license GPL-3.0
---@version 1.2.1
local f = {}
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
    local metatable = getmetatable(t)
    if metatable and metatable.__len then
        return metatable.__len(t)
    end
    return #t
end

--- Generates a table like {4, 5, 6, 7}.
---@param min integer The inclusive lower bound of the range. Defaults to `1`.
---@param max integer The inclusive upper bound of the range. Defaults to `1`.
---@param step integer The step between elements. Defaults to `1`.
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
---@param func (function(value, key) -> any) The mapping function. Defaults to `f.id`.
---@param f_pairs pairs The method to iterate over `obj`. Defaults to `pairs`. 
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
---@param seed (any) The initial value for the accumulator. By default, uses the first value in `obj` (and skips reducing that index).
---@param func (function(accumulator, value, key) -> accumulator) The reduction function.
---@param f_ipairs (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `ipairs`.
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
---@param func (function(value, key) -> bool) The predicate function.
---@param f_pairs (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `pairs`.
function f.any(obj, func, f_pairs)
    f_pairs = f_pairs or pairs
    for k, v in f_pairs(obj) do
        if func(v, k) then
            return true
        end
    end
    return false
end

--- Returns `true` if and only if `func(obj[k])` is truthy for all `k`. Otherwise, returns false.
---@param obj (table) The table to reduce.
---@param func (function(value, key) -> bool) The predicate function.
---@param f_pairs (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `pairs`.
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
---@param func (function(value, key) -> bool) The predicate function.
---@param f_pairs (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `pairs`.
function f.none(obj, func, f_pairs)
    f_pairs = f_pairs or pairs
    for k, v in f_pairs(obj) do
        if func(v, k) then
            return false
        end
    end
    return true
end

--- Returns a new table with only the elements which pass a test.
---@param obj (table) The table to filter.
---@param func (function(value, key) -> bool) The predicate function.
---@param f_pairs (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `pairs`.
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
---@param start (integer) The inclusive minimum index. Defaults to `1`.
---@param _end (integer) The inclusive maximum index. Defaults to infinity.
---@param f_ipairs (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `ipairs`.
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

--- Helper function for indexing into a table.
---@param obj table
function f.index(obj)
    return function(i)
        return obj[i]
    end
end

--- Runs a function on every value in the table.
---@param obj (table) The table to use.
---@param func (function(value, key) -> any) The function to run. Defaults to `f.id`.
---@param f_pairs pairs The method to iterate over `obj`. Defaults to `pairs`. 
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
---@param f_pairs_a pairs The method to iterate over `a`. Defaults to `pairs`.
---@param f_pairs_b pairs The method to iterate over `b`. Defaults to `pairs`.
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
---@param f_ipairs_a pairs The method to iterate over `a`. Defaults to `ipairs`.
---@param f_ipairs_b pairs The method to iterate over `b`. Defaults to `ipairs`.
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

--- Generates a table like {4, 5, 6, 7}.
---@param min integer The inclusive lower bound of the range. Defaults to `1`.
---@param max integer The inclusive upper bound of the range. Defaults to no upper bound.
---@param step integer The step between elements. Defaults to `1`.
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
---@param func (fcuntion(value, key) -> any) The mapping function. Defaults to `f.id`.
---@param f_pairs pairs The method to iterate over `obj`. Defaults to `pairs`. 
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
---@param f_pairs (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `pairs`.
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
---@param start (integer) The inclusive minimum index. Defaults to `1`.
---@param _end (integer) The inclusive maximum index. Defaults to infinity.
---@param f_ipairs (function(table) -> function, table, any) The method to iterate over `obj`. Defaults to `ipairs`.
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
---@param func (function(value, key) -> any) The function to run. Defaults to `f.id`.
---@param f_pairs pairs The method to iterate over `obj`. Defaults to `pairs`. 
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
---@param f_pairs_a pairs The method to iterate over `a`. Defaults to `pairs`.
---@param f_pairs_b pairs The method to iterate over `b`. Defaults to `pairs`.
function f.lazy.merge(a, b, f_pairs_a, f_pairs_b)
    error("Not implemented")
end

--- Concatenates two tables into a numerically-indexed table.
---@param a (table) The first table.
---@param b (table) The second table.
---@param f_ipairs_a pairs The method to iterate over `a`. Defaults to `ipairs`.
---@param f_ipairs_b pairs The method to iterate over `b`. Defaults to `ipairs`.
function f.lazy.concat(a, b, f_ipairs_a, f_ipairs_b)
    error("Not implemented")
end

--- Eagerly evaluates a lazy sequence.
--- The sequence will no longer use a metatable.
---@param obj table
function f.lazy.to_eager(obj)
    local metatable = getmetatable(t)
    if metatable and metatable.__eager then
        metatable.__eager(t)
    end
    return obj
end
