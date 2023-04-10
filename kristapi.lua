local api = {}
--local json = require("json")
local url = "https://krist.dev"

api.makeTransaction = function(privateKey, targetAddress, value, metadata)
    if metadata == nil then
        metadata = ""
    end
    local kutyus = {
        ["privatekey"]=privateKey,
        ["to"]=targetAddress,
        ["amount"]=value,
        ["metadata"]=metadata
    }
    local request = http.post(url.."/transactions/", --[[json.encode(kutyus)]]textutils.serialiseJSON(kutyus), {["Content-Type"] = "application/json"})
    return request.readAll()
end
api.getAddress = function(address)
    local request = http.get(url.."/addresses/"..address)
    --local data = json.decode(request.readAll())
    local data = textutils.unserialiseJSON(request.readAll())
    return data.address
end
function mysplit (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end
api.parseMeta = function(meta)
    local out = {}
    local a = mysplit(meta, ";")
    for k,v in ipairs(a) do
        local b = mysplit(v, "=")
        if b[2] ~= nil then
            out[b[1]] = b[2]
        else
            -- if matches the format of a krist address with metaname (ie test@shop.kst), we get the metaname, aka the test
            if(b[1]:match("^.+@.+%.kst$")) then
                local c = mysplit(b[1], "@")
                out["metaname"] = c[1]
            end
            --out[b[1]] = true
        end
    end
    return out
end
api.websocket = function()
    local fr = http.post(url.."/ws/start","")
    --local data = json.decode(fr.readAll())
    local data = textutils.unserialiseJSON(fr.readAll())
    local soc = data.url
    local socket = http.websocket(soc)
    --[[print(socket.send('{"type":"subscribe","event":"transactions","id":1}'))
    while true do
        print(socket.receive())
    end]]
    return socket
end

return api