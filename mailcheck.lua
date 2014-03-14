#!/usr/bin/env lua

-- Check for mail in maildirs.
-- Rewrite in lua of http://mailcheck.sourceforge.net/
version = '1.0'
require("lfs")

-- globals
globals = {}
globals.unread = 0
globals.new = 0


function read_config(configfile)
    local maildirs = {}
    local f = io.open(configfile)
    if f == nil then
        print( "Invalid config " .. configfile )
        os.exit(1)
    end
    while true do
        local line = f:read("*line")
        if line == nil then break end
        if lfs.attributes(line, 'mode') == 'directory' then
            table.insert(maildirs, line)
        else
            print("invalid line: " .. line)
        end
    end
    f:close()
    return maildirs
end


function is_unread(entry)
    -- entry like 1390_1.890.klap,U\=749,FMD5\=375:2,S
    local flags = entry:sub( entry:find(":"), nil )
    if flags:find("S") == nil then 
        return 'unread'
    else
        return nil
    end
end


function count_files(path)
    local cnt = 0
    for file in lfs.dir(path) do
        if file:find("=") ~= nil  then
            cnt = cnt + 1
        end
    end
    return cnt
end


function count_unread(path)
    local cnt = 0
    for file in lfs.dir(path) do
        if file:find(":") ~= nil  then
            if is_unread(file) ~= nil then
                cnt = cnt + 1
            end
        end
    end
    return cnt
end


function pj(...)
    sep = '/'
    result = ''
    for i, v in ipairs(arg) do
        if i == 1 then
            result = tostring(v)
        else
            result = result .. sep .. tostring(v)
        end
    end
    return result
end


function help()
    print("Usage: mailcheck [-hs] [-f rcfile]")
    print("Options:")
    print("    -s  - show only summary")
    print("    -f  - specify alternative rcfile location")
    print("    -h  - show this help screen")
    print("mailcheck-lua version " .. version .. "")
    os.exit(0)
end

function argparse()
    local configfile = pj(os.getenv("HOME"), '.mailcheckrc')
    local summary = false
    local _getnext = 0
    for k, v in pairs(arg) do
        if _getnext == 1 then
            configfile = v
            _getnext = 0
        else
            if v == '-h' then 
                help()
            elseif v == '-s' then 
                summary = true
            elseif v == '-f' then 
                _getnext = 1
            end
        end
    end
    return configfile, summary
end


function main()
    local configfile, summary = argparse()
    local maildirs = {}
    for k, pth in pairs(read_config(configfile)) do
        local _unread = count_unread( pj(pth, 'cur') )
        local _new = count_files( pj(pth, 'new') )

        globals.unread = globals.unread + _unread
        globals.new = globals.new + _new
        table.insert(maildirs, {name=pth, unread=_unread, new=_new})
    end
    if summary then
        if (globals.new + globals.unread) > 0 then
            print(string.format("%d new %d unread", globals.new, globals.unread))
        end
    else
        for k, v in pairs(maildirs) do 
            if (v.new + v.unread) > 0 then
                print(string.format("%s: %d new and %d unread message(s)", v.name, v.new, v.unread))
            end
        end
    end
end


main()
