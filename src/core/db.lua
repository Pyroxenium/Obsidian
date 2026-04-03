-- Obsidian Engine: Database Module
-- In-memory key-value store with collection support and optional persistence.
-- Built on top of storage.lua. Each collection is a separate file on disk.

local storage = require("core.storage")
local logger  = require("core.logger")

local DB = {}

-- ─── Collection ───────────────────────────────────────────────────────────────

local Collection = {}
Collection.__index = Collection

-- Check whether a record matches a filter table.
-- Filter values can be plain values (equality) or functions (predicate).
local function _matches(record, filter)
    for k, v in pairs(filter) do
        local rv = record[k]
        if type(v) == "function" then
            if not v(rv) then return false end
        else
            if rv ~= v then return false end
        end
    end
    return true
end

-- Deep-copy a table so callers can't mutate internal records by reference.
local function _copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = _copy(v)
    end
    return out
end

--- Create or load a collection.
-- @param name      Collection name (used as filename on disk).
-- @param opts      Optional table: { autosave = true, dir = "db/" }
function DB.open(name, opts)
    opts = opts or {}
    local self = setmetatable({}, Collection)
    self._name      = name
    self._dir       = opts.dir or "db/"
    self._autosave  = (opts.autosave ~= false)  -- default true
    self._records   = {}   -- list of records
    self._nextId    = 1    -- auto-increment counter

    -- Load existing data from disk
    local saved = storage.load(self._dir .. name)
    if saved then
        self._records = saved.records or {}
        self._nextId  = saved.nextId  or 1
        logger.info("DB: Loaded collection '" .. name .. "' (" .. #self._records .. " records)")
    end

    return self
end

-- ─── Write Operations ─────────────────────────────────────────────────────────

--- Insert a new record. Automatically assigns an `_id` if not present.
-- Returns the inserted record (with _id).
function Collection:insert(record)
    local r = _copy(record)
    if r._id == nil then
        r._id = self._nextId
        self._nextId = self._nextId + 1
    else
        -- Keep nextId ahead of any manually supplied _id
        if type(r._id) == "number" and r._id >= self._nextId then
            self._nextId = r._id + 1
        end
    end
    table.insert(self._records, r)
    if self._autosave then self:flush() end
    return _copy(r)
end

--- Insert multiple records at once. Returns a list of inserted records.
function Collection:insertMany(list)
    local out = {}
    for _, rec in ipairs(list) do
        out[#out + 1] = self:insert(rec)
    end
    return out
end

--- Update all records matching `filter` with the fields in `patch`.
-- Patch values overwrite existing fields; other fields are untouched.
-- Returns the number of updated records.
function Collection:update(filter, patch)
    local count = 0
    for _, rec in ipairs(self._records) do
        if _matches(rec, filter) then
            for k, v in pairs(patch) do
                if k ~= "_id" then  -- _id is immutable
                    rec[k] = _copy(v)
                end
            end
            count = count + 1
        end
    end
    if count > 0 and self._autosave then self:flush() end
    return count
end

--- Upsert: update if exists, insert if not.
-- @param filter  Filter to find the existing record.
-- @param data    Full data to insert or merge into the matched record.
-- Returns "updated" or "inserted".
function Collection:upsert(filter, data)
    local existing = self:findOne(filter)
    if existing then
        self:update({ _id = existing._id }, data)
        return "updated"
    else
        self:insert(data)
        return "inserted"
    end
end

--- Delete all records matching `filter`.
-- Returns the number of deleted records.
function Collection:delete(filter)
    local kept  = {}
    local count = 0
    for _, rec in ipairs(self._records) do
        if _matches(rec, filter) then
            count = count + 1
        else
            kept[#kept + 1] = rec
        end
    end
    self._records = kept
    if count > 0 and self._autosave then self:flush() end
    return count
end

--- Delete all records in the collection.
function Collection:clear()
    local count = #self._records
    self._records = {}
    self._nextId  = 1
    if self._autosave then self:flush() end
    return count
end

-- ─── Read Operations ──────────────────────────────────────────────────────────

--- Return all records matching `filter` (or all records if filter is nil).
-- @param filter   Optional filter table.
-- @param opts     Optional { limit = N, offset = N, orderBy = "field", desc = bool }
function Collection:find(filter, opts)
    opts = opts or {}
    local results = {}

    for _, rec in ipairs(self._records) do
        if not filter or _matches(rec, filter) then
            results[#results + 1] = _copy(rec)
        end
    end

    -- Optional sort
    if opts.orderBy then
        local field = opts.orderBy
        local desc  = opts.desc == true
        table.sort(results, function(a, b)
            local av, bv = a[field], b[field]
            if av == nil then return false end
            if bv == nil then return true  end
            if desc then return av > bv else return av < bv end
        end)
    end

    -- Optional offset + limit
    if opts.offset or opts.limit then
        local start = (opts.offset or 0) + 1
        local stop  = opts.limit and (start + opts.limit - 1) or #results
        local sliced = {}
        for i = start, math.min(stop, #results) do
            sliced[#sliced + 1] = results[i]
        end
        return sliced
    end

    return results
end

--- Return the first record matching `filter`, or nil.
function Collection:findOne(filter)
    for _, rec in ipairs(self._records) do
        if not filter or _matches(rec, filter) then
            return _copy(rec)
        end
    end
    return nil
end

--- Return the record with the given `_id`, or nil.
function Collection:findById(id)
    return self:findOne({ _id = id })
end

--- Return the number of records matching `filter` (or total count if nil).
function Collection:count(filter)
    if not filter then return #self._records end
    local n = 0
    for _, rec in ipairs(self._records) do
        if _matches(rec, filter) then n = n + 1 end
    end
    return n
end

-- ─── Persistence ─────────────────────────────────────────────────────────────

--- Write the collection to disk immediately.
function Collection:flush()
    local ok, err = storage.save(self._dir .. self._name, {
        records = self._records,
        nextId  = self._nextId,
    })
    if not ok then
        logger.error("DB: Failed to flush '" .. self._name .. "': " .. tostring(err))
    end
    return ok
end

--- Drop the collection from disk and clear in-memory data.
function Collection:drop()
    self:clear()
    storage.delete(self._dir .. self._name)
    logger.info("DB: Dropped collection '" .. self._name .. "'")
end

--- Disable automatic flushing (useful for bulk ops — call flush() manually after).
function Collection:disableAutosave()
    self._autosave = false
end

--- Re-enable automatic flushing.
function Collection:enableAutosave()
    self._autosave = true
end

return DB
