-- mpv-cut.lua
-- Marks IN / OUT points and appends cuts to a text file

local in_point = nil
local out_point = nil

local output = os.getenv("VCUT_OUTPUT") or "cuts.txt"

local function pos()
    return mp.get_property_number("time-pos")
end

local function mark_in()
    in_point = pos()
    if in_point then
        mp.osd_message(string.format("IN  %.3f", in_point), 1)
    end
end

local function mark_out()
    out_point = pos()
    if out_point then
        mp.osd_message(string.format("OUT %.3f", out_point), 1)
    end
end

local function write_cut()
    if not in_point or not out_point or in_point >= out_point then
        mp.osd_message("Invalid cut", 2)
        return
    end

    local f = io.open(output, "a")
    if not f then
        mp.osd_message("Cannot write cuts file", 2)
        return
    end

    local path = mp.get_property("path")
    f:write(string.format("%s %.3f %.3f\n", path, in_point, out_point))
    f:close()

    mp.osd_message("Cut written", 1)

    in_point = nil
    out_point = nil
end

mp.add_key_binding("i", "mark_in", mark_in)
mp.add_key_binding("o", "mark_out", mark_out)
mp.add_key_binding("w", "write_cut", write_cut)

mp.register_event("file-loaded", function()
    mp.osd_message("i=IN  o=OUT  w=WRITE", 4)
end)
