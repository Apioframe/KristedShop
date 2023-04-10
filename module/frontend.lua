local config, kristapi, dw, glogger = _G.kristedData.config, _G.kristedData.kristapi, _G.kristedData.dw, _G.kristedData.logger

local logger = glogger.getLogger("frontend")


local itemCache = {}

-- the same as above but uses the itemcache variable. Stores the item data in the item cache and a timestamp. If it is older than 5 seconds then it updates it.
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
            if string.match(v, "chest") == "chest" or string.match(v, "ender_storage") == "ender_storage" then
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

function frontendold()
    local monitor = peripheral.find("monitor")
    y = 1
    by = 1
    function mprint(msg)
        monitor.setCursorPos(1,y)
        monitor.write(msg)
        y = y + 1
    end
    function rerender()
        y = 1
        monitor.setBackgroundColor(config.Theme["Background-Color"])
        monitor.clear()
        monitor.setTextColour(config.Theme["Text-Color"])
        monitor.setTextScale(0.5)
        mprint(config["Shop-Name"].."\n")
        mprint(config["Description"])
        mprint("Shop owned by: "..config["Owner"].."\n")
        --mprint("Running: Kristed\n")
        mprint("Kristed By: VectorTech team (Bagi_Adam, BomberPlayz_)")

        mprint("")
        local kukucska = {}
        local w,h = monitor.getSize()

        monitor.setCursorPos(1,y)
        y = y + 1
        monitor.write("Stock Name")
        monitor.setCursorPos(w-#("price")+1,y-1)
        monitor.write("price")
        function addItem(id, name, price)
            monitor.setCursorPos(1,y)
            y = y + 1
            monitor.write(stockLookup(id).."")
            monitor.setCursorPos(#("Stock")+2,y-1)
            monitor.write(name)
            monitor.setCursorPos(w-#(price.."kst")+1,y-1)
            monitor.write(price.."kst")
            table.insert(kukucska, {line=y-1,id=id,name=name,price=price,stock=stockLookup(id)})
        end
        --mprint("")
        --addItem("Stock", "Name", "")
        --addItem("Test", 10, 10)
        for k,v in ipairs(config.Items) do
            addItem(v.Id, v.Name, v.Price)
        end

        monitor.setCursorPos(1,h-1)
        monitor.write("To buy something: /pay "..config["Wallet-id"].." <price> itemname=<itemname>")
        monitor.setCursorPos(1,h)
        monitor.write("For example: /pay "..config["Wallet-id"].." "..config.Items[1].Price.." itemname="..config.Items[1].Name)
        monitor.setCursorPos(w-#("Kristed v"..config.Version)+1,h)
        monitor.write("Kristed v"..config.Version)
        return kukucska
    end
    local kuka = rerender()
    while true do
        --rerender()
        for k,v in ipairs(kuka) do
            if stockLookup(v.id) ~= v.stock then
                local w,h = monitor.getSize()
                monitor.setCursorPos(1,v.line)
                monitor.clearLine()
                monitor.write(stockLookup(v.id).."")
                monitor.setCursorPos(#("Stock")+2,v.line)
                monitor.write(v.name)
                monitor.setCursorPos(w-#(v.price.."kst")+1,v.line)
                monitor.write(v.price.."kst")
                kuka[k].stock = stockLookup(v.id)
            end
        end
        os.sleep(10)
    end
end

function frontend(layout)

    local itemCache = {}

    local monitor = peripheral.find("monitor")
    local w,h = monitor.getSize()
    local y = 1
    local by = 0
    function mprint(msg,xstart,xend,align,halign)
        if xstart == nil then
            xstart = 1
        end
        if xend == nil then
            xend = w
        end
        if align == nil then
            align = "left"
        end
        if halign == nil then
            halign = "top"
        end
        monitor.setCursorPos(xstart,fy or y)
        if align == "left" then
            if halign == "top" then
                monitor.write(msg)
                y = y + 1
            elseif halign == "center" then
                monitor.setCursorPos(xstart,math.floor((h/2)-(#msg/2)))
                monitor.write(msg)
            elseif halign == "bottom" then
                monitor.setCursorPos(xstart,h-by)
                monitor.write(msg)
                by = by + 1
            end
        elseif align == "center" then
            --print(xstart, xend, msg)
            --print(math.floor((xend-xstart)/2-#msg/2))


            --monitor.setCursorPos(math.floor((xend-xstart)/2-#msg/2)+xstart,y)
            --monitor.write(msg)
            if halign == "top" then
                monitor.setCursorPos(math.floor((xend-xstart)/2-#msg/2)+xstart,y)
                monitor.write(msg)
                y = y + 1
            elseif halign == "center" then
                monitor.setCursorPos(math.floor((xend-xstart)/2-#msg/2)+xstart,math.floor((h/2)-(#msg/2)))
                monitor.write(msg)
            elseif halign == "bottom" then
                monitor.setCursorPos(math.floor((xend-xstart)/2-#msg/2)+xstart,h-by)
                monitor.write(msg)
                by = by + 1
            end
        elseif align == "right" then
            --monitor.setCursorPos(xend-#msg,y)
            --monitor.write(msg)
            if halign == "top" then
                monitor.setCursorPos(xend-#msg,y)
                monitor.write(msg)
                y = y + 1
            elseif halign == "center" then
                monitor.setCursorPos(xend-#msg,math.floor((h/2)-(#msg/2)))
                monitor.write(msg)
            elseif halign == "bottom" then
                monitor.setCursorPos(xend-#msg,h-by)
                monitor.write(msg)
                by = by + 1
            end
        end
    end


    local function esc(x)
        return (x:gsub('%%', '%%%%')
                 :gsub('^%^', '%%^')
                 :gsub('%$$', '%%$')
                 :gsub('%(', '%%(')
                 :gsub('%)', '%%)')
                 :gsub('%.', '%%.')
                 :gsub('%[', '%%[')
                 :gsub('%]', '%%]')
                 :gsub('%*', '%%*')
                 :gsub('%+', '%%+')
                 :gsub('%-', '%%-')
                 :gsub('%?', '%%?'))
    end

    function render()
        y = 1
        by = 0

        -- pass 1, render the background and set the text' xstart and xend based on the 'width' property in the elements of layout. If the overall width is bigger than the monitor's width, it will be resized to fit the monitor's width.
        -- if it is smaller, it is stretched to fit the monitor's width.

        local overallWidth = 0

        for k,v in ipairs(layout) do
            if v.width == nil then
                if v.text then
                    v.width = w
                else
                    v.width = w
                end
            end
            overallWidth = overallWidth + v.width

            if v.text then
                -- check if the text contains things like {Shop-Name} {Shop-Description} etc.
                -- the text may have a "-" symbol too. Make it so that it won't confuse the pattern
                local text = v.text
                for kk,vv in pairs(config) do
                    --print("{"..kk.."}")
                    text = string.gsub(text, "{"..esc(kk).."}", vv)
                end
                --print(text)
                v.text = text
            end
        end

        local multiplier = 1
        --print(multiplier)

        local xer = 1

        for k,v in ipairs(layout) do
            if v.width == nil then
                v.width = w
            end
            v.width = v.width * multiplier

            if v.align == nil then
                v.align = "left"
            end

            if v.xstart == nil then
                v.xstart = 1
                xer = xer + v.width


            end
            if v.xend == nil then
                v.xend = v.xstart + v.width
            end

        end

        local bg, tc = 0,0

        for k,v in ipairs(layout) do
            if v.type == "background" then
                bg = tonumber(v.bg)
                tc = tonumber(v.text)
            end
        end



        for k,v in ipairs(layout) do
            if v.background ~= nil then
                monitor.setBackgroundColor(v.background)
            else
                monitor.setBackgroundColor(bg)
            end
            if v.textcolor ~= nil then
                monitor.setTextColour(tonumber(v.color))
            else
                monitor.setTextColour(tc)
            end
            if v.type == "Header" then
                monitor.setCursorPos(v.xstart,v.y and v.y or y)
                monitor.setBackgroundColor(tonumber(v.background or bg))
                --monitor.write(string.rep(" ",v.xend-v.xstart+1))
                mprint(string.rep(" ",v.xend-v.xstart+1),v.xstart,v.xend,"left",v.align_h)
                monitor.setCursorPos(v.xstart,v.y and v.y+1 or y)
                monitor.setBackgroundColor(tonumber(v.background or bg))
                --monitor.write(string.rep(" ",v.xend-v.xstart+1))

                mprint(string.rep(" ",v.xend-v.xstart+1),v.xstart,v.xend,"left",v.align_h)
                monitor.setCursorPos(v.xstart,y)
                y = y - 1
                mprint(v.text,v.xstart,v.xend,"center", v.align_h)

                -- draw a horizontal line below the header
                monitor.setCursorPos(v.xstart,v.y and v.y+2 or y)
                --monitor.write(string.rep(" ",v.xend-v.xstart+1))
                mprint(string.rep(" ",v.xend-v.xstart+1),v.xstart,v.xend,"left",v.align_h)
            end
            if v.type == "Text" then
                if v.lasttext and v.lasttext ~= v.text then
                    -- clear ONLY the area where the text was but not the whole line
                    monitor.setCursorPos(v.xstart,v.y and v.y or y)
                    monitor.setBackgroundColor(tonumber(v.background or bg))
                    monitor.write(string.rep(" ",v.xend-v.xstart+1))
                end
                if v.color then
                    monitor.setTextColour(tonumber(v.color))
                end
                mprint(v.text,v.xstart,v.xend,v.align,v.align_h)
                v.lasttext = v.text
            end
            if v.type == "SellTable" then
                local colors = v.colors
                local cIndex = 1

                local overallWidther = 0
                for i,j in ipairs(v.columns) do
                    -- set xstart and xend. Do almost the same as in the first pass.
                    if j.width == nil then
                        j.width = w/4
                    end
                    overallWidther = overallWidther + j.width
                end
                local multiplierer = (v.xend-v.xstart)/overallWidther
                local xor = v.xstart
                -- write the column names centered
                for i,j in ipairs(v.columns) do
                    if j.width == nil then
                        j.width = w/4
                    end
                    j.width = j.width * multiplierer
                    if j.xstart == nil then
                        j.xstart = xor
                        xor = xor + j.width
                    end
                    if j.xend == nil then
                        j.xend = j.xstart + j.width
                    end
                end

                cIndex = cIndex + 1
                if cIndex > #colors.background then
                    cIndex = 1
                end
                for i,j in ipairs(v.columns) do
                    monitor.setCursorPos(j.xstart,y)
                    monitor.setBackgroundColor(v.colors.header or colors.background[cIndex])
                    monitor.write(string.rep(" ",j.xend-j.xstart+1))
                    --monitor.setCursorPos(j.xstart,y)
                    monitor.setTextColour(colors.text[cIndex])
                    mprint(j.name,j.xstart,j.xend,j.align, v.align_h)
                    y = y - 1

                end

                y = y + 1



                for kk,vv in ipairs(config.Items) do


                    --print(v.xend-v.xstart)
                    cIndex = cIndex + 1
                    if cIndex > #colors.background then
                        cIndex = 1
                    end
                    monitor.setBackgroundColor(colors.background[cIndex])
                    monitor.setTextColour(colors.text[cIndex])
                    for i,j in ipairs(v.columns) do

                        local text = j.text
                        text = string.gsub(text, "{name}", vv.Name)
                        text = string.gsub(text, "{price}", vv.Price)
                        text = string.gsub(text, "{stock}", stockLookup(vv.rawId,vv.Id,vv.filters))
                        text = string.gsub(text, "{alias}", vv.Alias or "")

                        if not j.lasttext or j.lasttext ~= text or true then

                            --monitor.setCursorPos(j.xstart,y)

                            --monitor.write(string.rep(" ",j.xend-j.xstart+1))
                            mprint(string.rep(" ",j.xend-j.xstart+1),j.xstart,j.xend,"left",v.align_h)
                            y = y-1
                            --monitor.setCursorPos(j.xstart,y)

                            mprint(text,j.xstart,j.xend,j.align, v.align_h)
                            y = y - 1
                            j.lasttext = text
                        end

                    end
                    y = y + 1
                end
            end
        end
    end
    local bg, tc = 0,0

    for k,v in ipairs(layout) do
        if v.type == "background" then
            bg = tonumber(v.bg)
            tc = tonumber(v.text)
        end
    end
    monitor.setBackgroundColor(bg)
    monitor.clear()
    local lele = #layout
    while true do
        if lele ~= #layout then
            lele = #layout
            monitor.setBackgroundColor(bg)
            monitor.clear()
        end
        render()
        os.sleep(0.25)
    end
end

function showError(err)
    logger.log(1, "Critical error: " .. err)
    local monitor = peripheral.find("monitor")
    monitor.setBackgroundColor(0x100)
    monitor.setTextColor(0x4000)
    monitor.clear()
    monitor.setCursorPos(1,1)
    monitor.write("The shop had an error")
    monitor.setCursorPos(1,2)
    monitor.write(err)
end

function start()
    local layout = require("../layout")
    _G.kristedData.layout = layout
    local updater = require("../frontend-modules/updater")
    parallel.waitForAny(function()
        local stat, err = pcall(updater,layout)
        if not stat then
            showError(err)
        end
    end,
    function()
        local stat, err = pcall(frontend,layout)
        if not stat then
            showError(err)
        end
    end)
end

return start