--[[
  24HG Forge Conky Lua Helper
  Pure-Lua JSON parser for flat objects + Hub/server status display
  No external dependencies
]]

-- ─── Minimal JSON parser for flat objects & arrays of flat objects ───────────

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function parse_string(s, pos)
    -- pos should point at opening quote
    local i = pos + 1
    local result = {}
    while i <= #s do
        local c = s:sub(i, i)
        if c == '\\' then
            local nc = s:sub(i + 1, i + 1)
            if     nc == '"'  then result[#result + 1] = '"'
            elseif nc == '\\' then result[#result + 1] = '\\'
            elseif nc == '/'  then result[#result + 1] = '/'
            elseif nc == 'n'  then result[#result + 1] = '\n'
            elseif nc == 't'  then result[#result + 1] = '\t'
            elseif nc == 'r'  then result[#result + 1] = '\r'
            else result[#result + 1] = nc end
            i = i + 2
        elseif c == '"' then
            return table.concat(result), i + 1
        else
            result[#result + 1] = c
            i = i + 1
        end
    end
    return table.concat(result), i
end

local function skip_ws(s, pos)
    return s:match("^%s*()", pos)
end

local function parse_value(s, pos)
    pos = skip_ws(s, pos)
    local c = s:sub(pos, pos)

    if c == '"' then
        return parse_string(s, pos)
    elseif c == '{' then
        return parse_object(s, pos)
    elseif c == '[' then
        return parse_array(s, pos)
    elseif s:sub(pos, pos + 3) == 'true' then
        return true, pos + 4
    elseif s:sub(pos, pos + 4) == 'false' then
        return false, pos + 5
    elseif s:sub(pos, pos + 3) == 'null' then
        return nil, pos + 4
    else
        -- number
        local num_str = s:match("^%-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
        if num_str then
            return tonumber(num_str), pos + #num_str
        end
        return nil, pos
    end
end

function parse_object(s, pos)
    local obj = {}
    pos = pos + 1  -- skip {
    pos = skip_ws(s, pos)
    if s:sub(pos, pos) == '}' then return obj, pos + 1 end

    while pos <= #s do
        pos = skip_ws(s, pos)
        if s:sub(pos, pos) ~= '"' then break end
        local key
        key, pos = parse_string(s, pos)
        pos = skip_ws(s, pos)
        pos = pos + 1  -- skip :
        local val
        val, pos = parse_value(s, pos)
        obj[key] = val
        pos = skip_ws(s, pos)
        if s:sub(pos, pos) == ',' then
            pos = pos + 1
        elseif s:sub(pos, pos) == '}' then
            return obj, pos + 1
        else
            break
        end
    end
    return obj, pos
end

function parse_array(s, pos)
    local arr = {}
    pos = pos + 1  -- skip [
    pos = skip_ws(s, pos)
    if s:sub(pos, pos) == ']' then return arr, pos + 1 end

    while pos <= #s do
        local val
        val, pos = parse_value(s, pos)
        arr[#arr + 1] = val
        pos = skip_ws(s, pos)
        if s:sub(pos, pos) == ',' then
            pos = pos + 1
        elseif s:sub(pos, pos) == ']' then
            return arr, pos + 1
        else
            break
        end
    end
    return arr, pos
end

local function read_json(filepath)
    local path = filepath:gsub("^~", os.getenv("HOME") or "/root")
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    if not content or #content == 0 then return nil end
    local ok, result = pcall(parse_value, content, 1)
    if ok then return result end
    return nil
end


-- ─── Public API ─────────────────────────────────────────────────────────────

--- Parse a JSON file and return the value for a top-level key.
-- @param filepath  Path to JSON file (~ expanded)
-- @param key       Top-level key to retrieve
-- @return string representation of the value, or "--"
function conky_parse_json(filepath, key)
    local data = read_json(filepath)
    if not data or data[key] == nil then return "--" end
    return tostring(data[key])
end

--- Format top 5 servers from ~/.cache/forge/server-status.json
--  Expected format: array of { "name": "...", "players": N, "max": N, "status": "online" }
function conky_server_status()
    local servers = read_json("~/.cache/forge/server-status.json")
    if not servers or type(servers) ~= "table" or #servers == 0 then
        return "${color2}  No server data${color}"
    end

    -- Sort by player count descending
    table.sort(servers, function(a, b)
        return (tonumber(a.players) or 0) > (tonumber(b.players) or 0)
    end)

    local lines = {}
    local count = math.min(5, #servers)
    for i = 1, count do
        local s = servers[i]
        local name = s.name or "Unknown"
        -- Truncate long names
        if #name > 22 then
            name = name:sub(1, 20) .. ".."
        end
        local players = tonumber(s.players) or 0
        local max     = tonumber(s.max) or 0
        local status  = s.status or "offline"

        local status_color
        if status == "online" and players > 0 then
            status_color = "${color0}"   -- cyan for active
        elseif status == "online" then
            status_color = "${color2}"   -- dim for empty
        else
            status_color = "${color 993333}"  -- red-ish for offline
        end

        lines[#lines + 1] = string.format(
            "%s  %-22s %s%d/%d${color}",
            "${color2}", name, status_color, players, max
        )
    end

    return table.concat(lines, "\n")
end

--- Format hub info from ~/.cache/forge/hub-state.json
--  Expected format: { "username": "...", "notifications": N, "friends_online": N }
function conky_hub_status()
    local hub = read_json("~/.cache/forge/hub-state.json")
    if not hub or type(hub) ~= "table" then
        return "${color2}  Not signed in${color}"
    end

    local username = hub.username or "Guest"
    local notifs   = tonumber(hub.notifications) or 0
    local friends  = tonumber(hub.friends_online) or 0

    local notif_display
    if notifs > 0 then
        notif_display = string.format("${color0}%d new${color}", notifs)
    else
        notif_display = "${color2}none${color}"
    end

    local lines = {
        string.format("${color2}  User${goto 80}${color1}%s${color}", username),
        string.format("${color2}  Notifications${goto 80}%s", notif_display),
        string.format("${color2}  Friends Online${goto 80}${color0}%d${color}", friends),
    }

    return table.concat(lines, "\n")
end
