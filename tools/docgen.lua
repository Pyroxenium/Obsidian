-- Obsidian documentation generator (a tool, not part of the engine).
--
-- Parses the sources under src/ and writes Markdown files into docs/.
-- The source of truth is the LuaLS annotations the engine already carries:
--
--   --- Description lines directly above a declaration.
--   ---@class Name : Base        starts a type; following @field lines join it
--   ---@field name type desc     (public unless prefixed private/protected
--                                 or the name starts with "_")
--   ---@alias Name definition
--   ---@param name type desc     (methods; "name?" or "type?" marks optional)
--   ---@return type name desc    (methods; comma-separated tuples supported)
--   ---@usage local x = ...      (methods, may span several lines)
--
-- Methods whose name starts with "_" and local functions are private and are
-- skipped. Methods are grouped by their owner symbol (Buffer, Surface, ...),
-- so one file may document several types.
--
-- Runs both inside CraftOS-PC/CC:Tweaked (uses the fs API) and under a plain
-- Lua interpreter (falls back to io + a directory listing), so it can be
-- wired into CI later.
--
-- Usage:
--   docgen [outputDir]   generate Markdown (default: docs/)
--   docgen --check       parse and validate without writing files

local args = { ... }

----------------------------------------------------------------------------
-- runtime abstraction: CC:Tweaked fs, or plain Lua io
----------------------------------------------------------------------------

local hasFs = type(fs) == "table" and type(fs.open) == "function"

local path = {}

function path.combine(a, b)
    if a == nil or a == "" then return b end
    if b == nil or b == "" then return a end
    return (a:gsub("/+$", "")) .. "/" .. (b:gsub("^/+", ""))
end

function path.dir(p)
    local parent = p:match("^(.*)/[^/]*$")
    return parent or ""
end

function path.name(p)
    return p:match("([^/]*)$")
end

local isWindows = package.config:sub(1, 1) == "\\"

local io_ = {}

function io_.exists(p)
    if hasFs then return fs.exists(p) end
    local handle = io.open(p, "r")
    if handle then handle:close() return true end
    return false
end

function io_.list(dir)
    local names = {}
    if hasFs then
        for _, entry in ipairs(fs.list(dir)) do names[#names + 1] = entry end
        table.sort(names)
        return names
    end
    local command = isWindows
        and ('dir /b "' .. dir:gsub("/", "\\") .. '" 2>nul')
        or ('ls -1 "' .. dir .. '" 2>/dev/null')
    local pipe = io.popen(command)
    if pipe then
        for line in pipe:lines() do
            line = line:gsub("[\r\n]", "")
            if line ~= "" then names[#names + 1] = line end
        end
        pipe:close()
    end
    table.sort(names)
    return names
end

function io_.read(p)
    if hasFs then
        local handle = fs.open(p, "r")
        if not handle then error("docgen: cannot read " .. p, 0) end
        local content = handle.readAll()
        handle.close()
        return content
    end
    local handle = io.open(p, "r")
    if not handle then error("docgen: cannot read " .. p, 0) end
    local content = handle:read("*a")
    handle:close()
    return content
end

function io_.write(p, content)
    local directory = path.dir(p)
    if directory ~= "" then
        if hasFs then
            if not fs.exists(directory) then fs.makeDir(directory) end
        elseif isWindows then
            os.execute('if not exist "' .. directory:gsub("/", "\\")
                .. '" mkdir "' .. directory:gsub("/", "\\") .. '" 2>nul')
        else
            os.execute('mkdir -p "' .. directory .. '"')
        end
    end
    if hasFs then
        local handle = fs.open(p, "w")
        if not handle then error("docgen: cannot write " .. p, 0) end
        handle.write(content)
        handle.close()
        return
    end
    local handle = io.open(p, "w")
    if not handle then error("docgen: cannot write " .. p, 0) end
    handle:write(content)
    handle:close()
end

----------------------------------------------------------------------------
-- configuration
----------------------------------------------------------------------------

-- Output layout mirrors src/. Files without an explicit list are discovered.
local categories = {
    { folder = "",         label = "Runtime", files = { "engine" } },
    { folder = "core",     label = "Core" },
    { folder = "core/ui",  label = "UI" },
    { folder = "",         label = "Formats", files = { "flimg" } },
}

-- Not part of the public API surface. Keyed by path relative to src/ so that
-- src/init.lua is skipped while src/core/ui/init.lua (the UI module) is not.
local skip = {
    ["init"]       = true, -- bootstrap shim, no API
    ["core/debug"] = true, -- internal shared state table
}

-- Owner symbol in the source -> documented @class name, for the cases where
-- the two differ. A mapping is only applied when that @class actually exists
-- somewhere in src/, so this table can never invent a type that isn't real;
-- add the annotation and the mapping starts working by itself.
local ownerClass = {
    Math           = "MathModule",
    Vector2        = "Vec2",
    handle_methods = "TweenEntry",
    tilemap        = "TilemapInstance",
    thread         = "Thread",
    ECS            = "ECSModule",
    Physics        = "PhysicsModule",
    Pathfinding    = "PathfindingModule",
    InputMapper    = "InputMapperModule",
    Console        = "ConsoleModule",
    Error          = "ErrorModule",
    Serialization  = "SerializationModule",
    Scene          = "SceneModule",
    UI             = "UIModule",
    M              = "UIElement",
    ai             = "AIModule",
    camera         = "CameraModule",
    buffer         = "BufferModule",
    color          = "ColorModule",
    input          = "InputModule",
    loader         = "LoaderModule",
    logger         = "LoggerModule",
    network        = "NetworkModule",
    particles      = "ParticlesModule",
    server         = "ServerModule",
    storage        = "StorageModule",
    flimg          = "FlimgModule",
}

local checkOnly, requestedOut = false, nil
for _, arg in ipairs(args) do
    if arg == "--check" then
        checkOnly = true
    elseif arg:sub(1, 2) ~= "--" then
        requestedOut = arg
    end
end

local function findRoot()
    local candidates = {}
    if hasFs and shell then
        local running = shell.getRunningProgram()
        candidates[#candidates + 1] = path.dir(path.dir(running))
        if shell.dir then candidates[#candidates + 1] = shell.dir() end
    end
    candidates[#candidates + 1] = ""
    candidates[#candidates + 1] = ".."
    for _, candidate in ipairs(candidates) do
        if io_.exists(path.combine(candidate, "src/engine.lua")) then
            return candidate
        end
    end
    error("docgen: cannot find repository root (expected src/engine.lua)", 0)
end

local root = findRoot()
local srcDir = path.combine(root, "src")
local outDir = requestedOut or path.combine(root, "docs")

----------------------------------------------------------------------------
-- parsing
----------------------------------------------------------------------------

local function trim(s)
    return (s or ""):match("^%s*(.-)%s*$")
end

local function splitList(value)
    local result = {}
    for item in (value or ""):gmatch("[^,]+") do
        item = trim(item)
        if item ~= "" then result[#result + 1] = item end
    end
    return result
end

--- Splits a LuaLS type from the human description following it. Whitespace
--- inside table<...>, tuples and function parameters stays part of the type,
--- and a trailing comma continues the type (tuple returns like
--- "number, number offset").
local function splitTypeAndDescription(value)
    value = trim(value)
    local depth = 0
    for i = 1, #value do
        local char = value:sub(i, i)
        if char == "<" or char == "(" or char == "[" or char == "{" then
            depth = depth + 1
        elseif char == ">" or char == ")" or char == "]" or char == "}" then
            depth = math.max(0, depth - 1)
        elseif char:match("%s") and depth == 0 then
            local previous = value:sub(1, i - 1):match("(%S)%s*$")
            local following = value:sub(i + 1):match("^%s*(.)")
            local functionType = value:match("^fun[%(<]") ~= nil
            local continues = previous == "," or following == ","
                or previous == "|" or following == "|"
            if functionType then
                continues = continues or previous == ":"
            end
            if not continues then
                return value:sub(1, i - 1), trim(value:sub(i + 1))
            end
        end
    end
    return value, ""
end

--- Turns a raw ---doc block into { desc, params, returns, usage }.
local function parseDocBlock(blockLines)
    local doc = { desc = {}, params = {}, returns = {}, usage = {} }
    local target = doc.desc
    for _, line in ipairs(blockLines) do
        local paramName, paramRest = line:match("^@param%s+(%S+)%s+(.+)$")
        local returnRest = line:match("^@return%s+(.+)$")
        local usageRest = line:match("^@usage%s*(.*)$")
        if paramName then
            local optional = paramName:sub(-1) == "?"
            if optional then paramName = paramName:sub(1, -2) end
            local paramType, paramDescription = splitTypeAndDescription(paramRest)
            -- LuaLS also allows the "?" on the type instead of the name.
            if paramType:sub(-1) == "?" then
                optional = true
                paramType = paramType:sub(1, -2)
            end
            if paramType:match("|%s*nil$") then optional = true end
            doc.params[#doc.params + 1] = {
                name = paramName,
                type = paramType,
                desc = paramDescription,
                optional = optional,
            }
            target = nil
        elseif returnRest then
            local returnType, returnDescription = splitTypeAndDescription(returnRest)
            local returnName
            -- Lowercase only: a capitalised first word is prose ("True if
            -- the entity exists"), not a return name.
            local name, description = returnDescription:match("^([a-z_][%w_]*)%s+(.+)$")
            if name then
                returnName, returnDescription = name, description
            elseif returnDescription:match("^[a-z_][%w_]*$") then
                returnName, returnDescription = returnDescription, ""
            end
            doc.returns[#doc.returns + 1] = {
                type = returnType,
                name = returnName,
                desc = returnDescription,
            }
            target = nil
        elseif usageRest then
            target = doc.usage
            if #usageRest > 0 then target[#target + 1] = usageRest end
        elseif line:match("^@") then
            target = nil -- unknown tag (e.g. @diagnostic, @cast): drop it
        elseif target then
            target[#target + 1] = line
        end
    end
    return doc
end

local function baseTypeName(name)
    return (name or ""):match("^([%w_%.]+)")
end

local function isPublicField(field)
    return field.visibility ~= "private"
        and field.visibility ~= "protected"
        and field.name:sub(1, 1) ~= "_"
end

local function parseFile(sourcePath, displayName)
    local content = io_.read(sourcePath)
    local sourceName = path.name(sourcePath):gsub("%.lua$", "")

    local page = {
        sourcePath = sourcePath,
        sourceName = sourceName,
        name = displayName or sourceName,
        header = {},
        methods = {},
        owners = {},      -- owner key -> { key, symbol, sep, class, methods }
        ownerOrder = {},
        types = {},
        typeByName = {},
        aliases = {},
        aliasByName = {},
    }

    local pending = {}
    local currentType = nil
    local inHeader = true

    for line in (content .. "\n"):gmatch("(.-)\n") do
        repeat

        -- leading "--" comment block (not "---") = page overview
        if inHeader then
            local headerText = line:match("^%-%-%s?(.*)$")
            if headerText ~= nil and not line:match("^%-%-%-") then
                page.header[#page.header + 1] = headerText
                break
            elseif trim(line) ~= "" then
                inHeader = false
            else
                break
            end
        end

        local docText = line:match("^%s*%-%-%-%s?(.*)$")
        if docText then
            local classDisplay, basesText =
                docText:match("^@class%s+(%S+)%s*:?[ \t]*(.*)$")
            local aliasDisplay, aliasDefinition =
                docText:match("^@alias%s+(%S+)%s+(.+)$")
            local fieldRest = docText:match("^@field%s+(.+)$")
            if classDisplay then
                local className = baseTypeName(classDisplay)
                local definition = {
                    name = className,
                    display = classDisplay,
                    bases = splitList(basesText),
                    desc = parseDocBlock(pending).desc,
                    fields = {},
                    fieldOrder = {},
                }
                page.types[#page.types + 1] = definition
                page.typeByName[className] = definition
                currentType = definition
                pending = {}
            elseif aliasDisplay then
                local aliasName = baseTypeName(aliasDisplay)
                local definition = {
                    name = aliasName,
                    display = aliasDisplay,
                    definition = trim(aliasDefinition),
                    desc = parseDocBlock(pending).desc,
                }
                page.aliases[#page.aliases + 1] = definition
                page.aliasByName[aliasName] = definition
                currentType = nil
                pending = {}
            elseif fieldRest and currentType then
                local first, rest = fieldRest:match("^(%S+)%s+(.+)$")
                local visibility
                if first == "public" or first == "private" or first == "protected" then
                    visibility = first
                    first, rest = rest:match("^(%S+)%s+(.+)$")
                end
                if first and rest then
                    local fieldType, description = splitTypeAndDescription(rest)
                    local optional = first:sub(-1) == "?"
                    if optional then first = first:sub(1, -2) end
                    if fieldType:sub(-1) == "?" then
                        optional = true
                        fieldType = fieldType:sub(1, -2)
                    end
                    local field = {
                        name = first,
                        type = fieldType,
                        desc = description,
                        visibility = visibility,
                        optional = optional,
                    }
                    currentType.fields[first] = field
                    currentType.fieldOrder[#currentType.fieldOrder + 1] = field
                end
                pending = {}
            else
                pending[#pending + 1] = docText
            end
            break
        end

        do
            local owner, sep, methodName, params =
                line:match("^function%s+([%w_]+)([:%.])([%w_]+)%s*%(([^%)]*)%)")
            if owner and methodName:sub(1, 1) ~= "_" then
                local doc = parseDocBlock(pending)
                -- Keyed by the symbol alone, so that a constructor written as
                -- "Brain.new" and instance methods written as "Brain:update"
                -- share one section. Each signature still shows its own
                -- separator.
                local key = owner
                local bucket = page.owners[key]
                if not bucket then
                    bucket = {
                        key = key,
                        symbol = owner,
                        sep = sep,
                        -- resolved against the type registry once every file
                        -- has been parsed; see resolveOwnerClasses()
                        class = owner,
                        candidate = ownerClass[owner],
                        methods = {},
                    }
                    page.owners[key] = bucket
                    page.ownerOrder[#page.ownerOrder + 1] = bucket
                end
                local method = {
                    owner = owner,
                    sep = sep,
                    name = methodName,
                    params = trim(params),
                    doc = doc,
                    bucket = bucket,
                }
                bucket.methods[#bucket.methods + 1] = method
                page.methods[#page.methods + 1] = method
            end
            if trim(line) ~= "" then
                pending = {}
                currentType = nil
            end
        end

        until true
    end

    return page
end

----------------------------------------------------------------------------
-- cross-file type resolution
----------------------------------------------------------------------------

local function buildTypeRegistry(pages)
    local registry = {}
    for _, page in ipairs(pages) do
        for _, definition in ipairs(page.types) do
            definition.page = page
            if not registry[definition.name] then
                registry[definition.name] = definition
            end
        end
    end
    return registry
end

--- An owner is renamed to its documented class only if that class really is
--- annotated somewhere. Otherwise the symbol as written in the source wins.
local function resolveOwnerClasses(pages, registry)
    for _, page in ipairs(pages) do
        for _, bucket in ipairs(page.ownerOrder) do
            if bucket.candidate and registry[bucket.candidate] then
                bucket.class = bucket.candidate
            elseif registry[bucket.symbol] then
                bucket.class = bucket.symbol
            end
        end
    end
end

--- Types worth printing on this page: everything reachable from its own
--- methods, owners and type fields. Keeps unrelated helper classes out.
local function publishedTypes(page)
    local wanted, queue = {}, {}
    local function scan(value)
        for identifier in (value or ""):gmatch("[%a_][%w_%.]*") do
            if not wanted[identifier]
                and (page.typeByName[identifier] or page.aliasByName[identifier]) then
                wanted[identifier] = true
                queue[#queue + 1] = identifier
            end
        end
    end

    for _, bucket in ipairs(page.ownerOrder) do scan(bucket.class) end
    for _, method in ipairs(page.methods) do
        for _, param in ipairs(method.doc.params) do scan(param.type) end
        for _, result in ipairs(method.doc.returns) do scan(result.type) end
    end
    -- A file with no methods at all still documents its types.
    if #page.methods == 0 then
        for _, definition in ipairs(page.types) do scan(definition.name) end
        for _, alias in ipairs(page.aliases) do scan(alias.name) end
    end

    local index = 1
    while index <= #queue do
        local name = queue[index]
        index = index + 1
        local alias = page.aliasByName[name]
        if alias then scan(alias.definition) end
        local definition = page.typeByName[name]
        if definition then
            for _, base in ipairs(definition.bases) do scan(base) end
            for _, field in ipairs(definition.fieldOrder) do
                if isPublicField(field) then scan(field.type) end
            end
        end
    end
    return wanted
end

----------------------------------------------------------------------------
-- markdown output
----------------------------------------------------------------------------

local function esc(s)
    return (s or ""):gsub("|", "\\|")
end

local function inlineCode(s)
    return "`" .. (s or ""):gsub("`", "\\`") .. "`"
end

local function anchor(text)
    return (text:lower():gsub("[^%w%s%-]", ""):gsub("%s+", "-"))
end

local function renderTypeSection(w, page, visibleTypes)
    local rendered = false
    for _, alias in ipairs(page.aliases) do
        if visibleTypes[alias.name] then
            if not rendered then w("## Types") w("") rendered = true end
            w("### " .. inlineCode(alias.display))
            w("")
            if #alias.desc > 0 then
                w(table.concat(alias.desc, "\n"))
                w("")
            end
            w("```lua")
            w(alias.display .. " = " .. alias.definition)
            w("```")
            w("")
        end
    end
    for _, definition in ipairs(page.types) do
        local publicFields = {}
        for _, field in ipairs(definition.fieldOrder) do
            if isPublicField(field) then publicFields[#publicFields + 1] = field end
        end
        -- A type with no description, no bases and no public fields would
        -- render as a bare heading. Say nothing instead.
        local worthShowing = #definition.desc > 0
            or #definition.bases > 0
            or #publicFields > 0
        if visibleTypes[definition.name] and worthShowing then
            if not rendered then w("## Types") w("") rendered = true end
            w("### " .. inlineCode(definition.display))
            w("")
            if #definition.bases > 0 then
                w("*extends " .. table.concat(definition.bases, ", ") .. "*")
                w("")
            end
            if #definition.desc > 0 then
                w(table.concat(definition.desc, "\n"))
                w("")
            end
            if #publicFields > 0 then
                w("| Field | Type | Description |")
                w("| --- | --- | --- |")
                for _, field in ipairs(publicFields) do
                    local suffix = field.optional and " *(optional)*" or ""
                    w("| " .. esc(field.name) .. suffix .. " | "
                        .. inlineCode(esc(field.type)) .. " | "
                        .. esc(field.desc) .. " |")
                end
                w("")
            end
        end
    end
end

local function renderMethod(w, method)
    w("### " .. method.owner .. method.sep .. method.name
        .. "(" .. method.params .. ")")
    w("")
    if #method.doc.desc > 0 then
        w(table.concat(method.doc.desc, "\n"))
        w("")
    end
    -- "---@param self X" on a colon method documents the implicit receiver.
    -- It carries no information for a reader, so drop it.
    local shown = 0
    for _, param in ipairs(method.doc.params) do
        if not (method.sep == ":" and param.name == "self") then
            local optional = param.optional and ", optional" or ""
            w("- **" .. param.name .. "** (" .. inlineCode(param.type) .. optional
                .. ") " .. param.desc)
            shown = shown + 1
        end
    end
    if shown > 0 then w("") end
    for _, ret in ipairs(method.doc.returns) do
        local name = ret.name and " **" .. ret.name .. "**" or ""
        w("- **returns**" .. name .. " (" .. inlineCode(ret.type) .. ") " .. ret.desc)
    end
    if #method.doc.returns > 0 then w("") end
    if #method.doc.usage > 0 then
        w("```lua")
        w(table.concat(method.doc.usage, "\n"))
        w("```")
        w("")
    end
end

local function renderPage(page)
    local out = {}
    local function w(s) out[#out + 1] = s end

    w("# " .. page.name)
    w("")
    if #page.header > 0 then
        w(trim(table.concat(page.header, "\n")))
        w("")
    end

    renderTypeSection(w, page, publishedTypes(page))

    -- One section per owner symbol. A single owner keeps the flat "Methods"
    -- heading; several owners (Buffer/Surface, DatabaseModule/Collection, ...)
    -- each get their own.
    local single = #page.ownerOrder == 1
    for _, bucket in ipairs(page.ownerOrder) do
        w(single and "## Methods" or ("## " .. bucket.class))
        w("")
        for _, method in ipairs(bucket.methods) do renderMethod(w, method) end
    end

    return table.concat(out, "\n")
end

----------------------------------------------------------------------------
-- run
----------------------------------------------------------------------------

local records = {}
local seenSource = {}

for _, category in ipairs(categories) do
    local names = category.files
    if not names then
        names = {}
        for _, file in ipairs(io_.list(path.combine(srcDir, category.folder))) do
            local moduleName = file:match("^(.+)%.lua$")
            if moduleName then names[#names + 1] = moduleName end
        end
    end

    for _, moduleName in ipairs(names) do
        local moduleKey = path.combine(category.folder, moduleName)
        if not skip[moduleKey] then
            local relative = path.combine(category.folder, moduleName .. ".lua")
            local sourcePath = path.combine(srcDir, relative)
            if not seenSource[relative] and io_.exists(sourcePath) then
                seenSource[relative] = true
                local display = moduleName == "init"
                    and path.name(category.folder) or moduleName
                local page = parseFile(sourcePath, display)
                records[#records + 1] = {
                    category = category,
                    page = page,
                    outRel = path.combine(category.folder, page.name .. ".md"),
                }
            end
        end
    end
end

if #records == 0 then
    error("docgen: no source files found under " .. srcDir, 0)
end

local pages = {}
for _, record in ipairs(records) do pages[#pages + 1] = record.page end
local registry = buildTypeRegistry(pages)
resolveOwnerClasses(pages, registry)

-- Stable, alphabetical order inside each category for the index.
table.sort(records, function(a, b)
    if a.category ~= b.category then
        local ia, ib
        for i, category in ipairs(categories) do
            if category == a.category then ia = i end
            if category == b.category then ib = i end
        end
        return ia < ib
    end
    return a.page.name < b.page.name
end)

local index = {}
local seenPaths = {}
local undocumented, totalMethods = {}, 0

for _, category in ipairs(categories) do
    local sectionOpen = false
    for _, record in ipairs(records) do
        if record.category == category then
            if not sectionOpen then
                index[#index + 1] = "## " .. category.label
                index[#index + 1] = ""
                sectionOpen = true
            end
            local key = record.outRel:lower()
            if seenPaths[key] then
                error("docgen: duplicate output path " .. record.outRel, 0)
            end
            seenPaths[key] = true

            record.content = renderPage(record.page)
            if trim(record.content) == "" then
                error("docgen: rendered empty page for " .. record.page.name, 0)
            end

            for _, method in ipairs(record.page.methods) do
                totalMethods = totalMethods + 1
                if #method.doc.desc == 0 then
                    undocumented[#undocumented + 1] =
                        record.page.name .. ": " .. method.owner
                        .. method.sep .. method.name
                end
            end

            local count = #record.page.methods
            index[#index + 1] = "- [" .. record.page.name .. "]("
                .. record.outRel:gsub("\\", "/") .. ") — "
                .. count .. (count == 1 and " method" or " methods")
        end
    end
    if sectionOpen then index[#index + 1] = "" end
end

local indexContent = "# Obsidian API reference\n\n"
    .. "Generated by `tools/docgen.lua` — do not edit by hand, edit the\n"
    .. "annotations in `src/` and regenerate.\n\n"
    .. table.concat(index, "\n")

if checkOnly then
    print(("docgen: %d pages, %d methods, %d without a description")
        :format(#records, totalMethods, #undocumented))
    for _, entry in ipairs(undocumented) do print("  " .. entry) end
else
    for _, record in ipairs(records) do
        io_.write(path.combine(outDir, record.outRel), record.content)
    end
    io_.write(path.combine(outDir, "README.md"), indexContent)
    print(("docgen: %d pages, %d methods -> %s (%d without a description)")
        :format(#records, totalMethods, outDir, #undocumented))
end
