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
        if file:find(":") ~= nil  then
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
        result = result .. tostring(v) .. sep
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
end

function argparse()
    local configfile = os.getenv("HOME") .. '/.mailcheckrc'
    local silent = false
    local _getnext = 0
    for k, v in pairs(arg) do
        if v == '-h' then 
            help()
        elseif v == '-s' then 
            silent = true
        elseif v == '-f' then 
            _getnext = 1
        end
        if _getnext == 1 then
            configfile = v
            _getnext = 0
        end
    end
end

argparse()

function main()
    for k, pth in pairs(read_config()) do
        local unread = count_unread( pj(pth, 'cur') )
        local new = count_files( pj(pth, 'new') )
        globals.unread = globals.unread + unread
        globals.new = globals.new + new
    end
    print(string.format("%d new %d unread", globals.new, globals.unread))
end


-- main()
