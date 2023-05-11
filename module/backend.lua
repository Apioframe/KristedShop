local config, kristapi, dw, glogger = _G.kristedData.config, _G.kristedData.kristapi, _G.kristedData.dw, _G.kristedData.logger

local logger = glogger.getLogger("backend")

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

local function checkFilter(item, filters)
    --logger.log(0,"Checking item: "..textutils.serialise(item))
    local o = true
    for k,v in pairs(filters) do
        --logger.log(3, "No filter found named: "..k.." (a nil value)")
        --logger.log(0,"filter: "..k)
        local b = v.callback(item)
        --logger.log(0,"filtra: "..tostring(b))
        if v.inverted then
            b = not b
        end
        if b == false then
            o = false
        end
    end
    return o
end

local itemCache = {}

local function stockLookup(rid, id, filter)
    if itemCache[rid] == nil then
        itemCache[rid] = {}
        itemCache[rid].count = 0
        itemCache[rid].time = os.time()-10
    end

    --logger.log(0,"KIBASZOTT? "..(os.time() - itemCache[rid].time))
    --logger.log(0,"RID: "..rid..", IC: "..textutils.serialise(itemCache[rid]))
    if os.time() - itemCache[rid].time > 0.05 then
        --logger.log(0,"CHECKING FOR: RID: "..rid)



        local count = 0
        local rawNames = peripheral.getNames()
        for k,v in ipairs(rawNames) do
            if string.match(v, "chest") == "chest" then
                local chest = peripheral.wrap(v)
                for kk,vv in pairs(chest.list()) do
                    if vv.name == id and checkFilter(chest.getItemDetail(kk),filter) then
                        --logger.log(0, "fos? "..filter, chest.getItemDetail(kk).displayName)
                        count = count + vv.count
                    end
                end
            end
        end
        --logger.log(0, "FOSTOS? RID: "..rid..", CO: "..count)
        itemCache[rid].count = count
        itemCache[rid].time = os.time()
    end
    return itemCache[rid].count
end



function preDropItem(id, filters, count)
    local stacks = {}
    local ca = count/64
    local marad = count
    for i=1,math.floor(ca),1 do
        table.insert(stacks, 64)
        marad = marad - 64
    end
    if ca ~= math.floor(ca) then
        table.insert(stacks, marad)
    end
    for k,v in ipairs(stacks) do
        while v > 0 do
            local dro = dropItem(id, filters, v)
            v = v - dro
        end
    end
end

function dropItem(id, filters, limit)
    local rawNames = peripheral.getNames()
    for k,v in ipairs(rawNames) do
        if string.match(v, "chest") == "chest" then
            local chest = peripheral.wrap(v)
            for kk,vv in pairs(chest.list()) do
                if vv.name == id and checkFilter(chest.getItemDetail(kk), filters) then
                    local co = chest.pushItems(config["Self-Id"],kk,limit,1)
                    turtle.drop(limit)
                    return co
                end
            end
        end
    end
end

-- returns true if yes,
-- otherwise the reason
function allowProcessPurchase(transaction)
    local meta = kristapi.parseMeta(transaction.metadata)
    if meta["metaname"] then
        meta["itemname"] = meta["metaname"]
    end
    if meta["itemname"] == nil then
        return false, "no itemname"
    end
    local item = nil
    for k,v in ipairs(config.Items) do
        if v.Name == meta["itemname"] or v.Alias == meta["itemname"] then
            item = v
        end
    end
    if item == nil then
        return false, "no such item"
    end
    if stockLookup(item.rawId,item.Id,item.filters) == 0 then
        return false, "out of stock of item"
    end
    if item.Price > transaction.value then
        return false, "Not enought Krist has been supplied for the item(s)"
    end
    if transaction.metadata ~= nil or transaction.sent_name ~= nil then
    else
        return false, "no meta"
    end
    return true
end

function mindTransaction(trans)
    if (trans.to == config["Wallet-id"]) and (trans.sent_name == nil and config["Accept-wallet-id"] or config["Wallet-vanity"] == "" and config["Accept-wallet-id"] or trans.sent_name == config["Wallet-vanity"]) then
        return true
    end
    return false
end

function initializeSocket()
    local socket = kristapi.websocket()
    _G.KristedSocket = socket
    socket.send('{"type":"subscribe","event":"transactions","id":1}')
    return function()
        local ok, dta = pcall(socket.receive)

        if not ok then
            logger.log(2, "Socket error: "..dta)
            socket = kristapi.websocket()
            _G.KristedSocket = socket
            socket.send('{"type":"subscribe","event":"transactions","id":1}')
            return soc
        end
        return dta
    end
end

function dispenseItem(trans, meta)
    local tc = false
    local vav = nil
    print(meta.itemname)
    for k,v in ipairs(config.Items) do
        if v.Name == meta.itemname or v.Alias == meta.itemname then
            tc = true
            vav = v
        end
    end
    local count = math.floor((trans.value / vav.Price)+0.5)
    local exchange = math.floor(trans.value - (stockLookup(vav.rawId,vav.Id,vav.filters)*vav.Price))
    if exchange >= 0 then
        preDropItem(vav.Id, vav.filters, stockLookup(vav.rawId,vav.Id,vav.filters))
        if exchange ~= 0 then
            if meta["return"] ~= nil then
                kristapi.makeTransaction(config["Wallet-Key"], trans.from, exchange, meta["return"]..";message=Here is your change")
            else
                kristapi.makeTransaction(config["Wallet-Key"], trans.from, exchange, "message=Here is your change")
            end
        end
    else
        preDropItem(vav.Id, vav.filters, count)
    end
    local change = ((trans.value / vav.Price)-count)*vav.Price
    if change >= 1 then
        if meta["return"] ~= nil then
            kristapi.makeTransaction(config["Wallet-Key"], trans.from, change, meta["return"]..";message=Here is your change")
        else
            kristapi.makeTransaction(config["Wallet-Key"], trans.from, change, "message=Here is your change")
        end
    end
    return count, exchange, change
end

function processWebhook(trans, meta, count, exchange, change, success)
    if config["Discord-Webhook"] then
        --[[dw.sendEmbed(config["Discord-Webhook-URL"], "Kristed", "Someone bought something", 0x0099ff,
                {{["name"]="From address",["value"]=trans.from},{["name"]="Value",["value"]=trans.value},{["name"]="Return address",["value"]=meta["return"]},{["name"]="Itemname",["value"]=meta.itemname},{["name"]="Meta",["value"]="`"..trans.metadata.."`"},{["name"]="Items dropped",["value"]=tostring(count)},{["name"]="Exchange",["value"]=tostring(exchange)},{["name"]="Change",["value"]=tostring(change)}})]]

        local embed = dw.sendBuilderEmbed()

        embed
                .setTitle("Kristed purchase info")
                .setDescription("Someone bought something")
                .setColor(0x0099ff)
                .addField().setName("From address").setValue(trans.from).setInline(true).endField()
                .addField().setName("Value").setValue(trans.value).setInline(true).endField()
                .addField().setName("Return address").setValue(meta["return"]).setInline(true).endField()
                .addField().setName("Itemname").setValue(meta.itemname).setInline(true).endField()
                --.addField().setName("Meta").setValue("`"..trans.metadata.."`").setInline(true).endField() -- Just a debug thing
                .addField().setName("Items dropped").setValue(tostring(count)).setInline(true).endField()
                .addField().setName("Exchange").setValue(tostring(exchange)).setInline(true).endField()
                .addField().setName("Change").setValue(tostring(change)).setInline(true).endField()
                .send(config["Discord-Webhook-URL"])

    end
end

function backend()
    local soc = initializeSocket()
    local layout = _G.kristedData.layout

    function dataReceived(dta)
        if dta.type == "event" and dta.event == "transaction" then
            local trans = dta.transaction
            if mindTransaction(trans) then
                local oka, moszonnyu = allowProcessPurchase(trans)
                if oka then
                    local meta = kristapi.parseMeta(trans.metadata)
                    if meta["metaname"] then
                        meta["itemname"] = meta["metaname"]
                    end
                    logger.log(1,"Payment received, from "..trans.from.." to "..trans.to..", value: "..trans.value..", return: "..meta["return"] or "no one")

                    local count, exchange, change = dispenseItem(trans, meta)

                    processWebhook(trans, meta, count, exchange, change, true, "Successful purchase")
                else

                    local meta = kristapi.parseMeta(trans.metadata)
                    if meta["metaname"] then
                        meta["itemname"] = meta["metaname"]
                    end
                    local embed = dw.sendBuilderEmbed()

                    embed
                            .setTitle("Kristed purchase failure")
                            .setDescription("Someone tried to buy something")
                            .setColor(0xff0000)
                            .addField().setName("Failure reason").setValue(moszonnyu).setInline(true).endField()
                            .addField().setName("From").setValue(trans.from).setInline(true).endField()
                            .addField().setName("Meta").setValue(textutils.serialise(meta)).endField()
                            .send(config["Discord-Webhook-URL"])

                    if meta["return"] ~= nil then
                        kristapi.makeTransaction(config["Wallet-Key"], trans.from, trans.value, meta["return"]..";message="..moszonnyu)
                    else
                        kristapi.makeTransaction(config["Wallet-Key"], trans.from, trans.value, "message="..moszonnyu)
                    end
                end
            end
        end
    end

    while true do
        local dta = soc()
        if not dta then
            logger.log(2, "Socket problem")
        else
            ok, dta = pcall(textutils.unserialiseJSON, dta)
            if not ok then
                logger.log(3, "JSON error: "..dta)
            else
                dataReceived(dta)
            end
        end
    end
end

return backend