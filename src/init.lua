-- Obsidian entry point.
--
-- The installer places this directory into a CC:Tweaked environment under the
-- name "obsidian", so user code loads the engine with:
--   local Engine = require("obsidian")
--
-- This file is the module loader. It reads Obsidian's own sources from the
-- directory it lives in and hands each module a private require, so the engine
-- never touches package.path and never shares package.loaded with the program
-- using it. Two copies of Obsidian on one computer stay independent.
--
-- Every module receives that loader as its first vararg:
--   local require = ...
--
-- The release bundles built by tools/bundle.lua use the same contract, so a
-- bundled engine and a source checkout load identically.

---@diagnostic disable: undefined-global

local args = { ... }

--- Obsidian's own directory.
---
--- Asking the chunk where it was loaded from is the only method that does not
--- depend on how the caller invoked it: a module is compiled with the chunk
--- name "@/path/to/init.lua". The (name, path) pair that CraftOS' require
--- passes is kept as a fallback for hosts without debug.getinfo.
---
--- Deliberately no fallback to shell.getRunningProgram(): that yields the
--- directory of the *calling* program, which would silently resolve modules
--- against the wrong tree instead of failing.
local function locate()
    local getinfo = _G.debug and _G.debug.getinfo
    if getinfo then
        local info = getinfo(1, "S")
        local source = info and info.source
        if type(source) == "string" and source:sub(1, 1) == "@" then
            return fs.getDir(source:sub(2))
        end
    end

    local path = args[2]
    if type(path) == "string" and path ~= "" then
        return fs.getDir(path)
    end

    error("Obsidian: cannot determine its own location. "
        .. 'Load it with require("obsidian").', 0)
end

local root = locate()
local loaded = {}
local loading = {}

--- Resolves a dotted module name against Obsidian's source tree.
--- "core.buffer" -> core/buffer.lua, "core.ui" -> core/ui/init.lua
local function loader(name)
    local cached = loaded[name]
    if cached ~= nil then return cached end
    if loading[name] then
        error("Obsidian: circular require of " .. tostring(name), 0)
    end

    local relative = name:gsub("%.", "/")
    local candidates = {
        fs.combine(root, relative .. ".lua"),
        fs.combine(root, relative .. "/init.lua"),
    }

    for _, path in ipairs(candidates) do
        if fs.exists(path) and not fs.isDir(path) then
            local chunk, err = loadfile(path)
            if not chunk then
                error("Obsidian: cannot load " .. name .. ": " .. tostring(err), 0)
            end
            -- Marked before running the chunk so that a cyclic require fails
            -- with a clear message instead of recursing until stack overflow.
            loading[name] = true
            local result = chunk(loader, name)
            loading[name] = nil
            loaded[name] = result == nil and true or result
            return loaded[name]
        end
    end

    error("Obsidian: module not found: " .. tostring(name), 0)
end

local ok, result = pcall(loader, "engine")
if not ok then
    error("Obsidian Loading Error: " .. tostring(result), 0)
end
return result
