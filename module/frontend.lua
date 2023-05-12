local config, kristapi, dw, glogger = _G.kristedData.config, _G.kristedData.kristapi, _G.kristedData.dw, _G.kristedData.logger

local logger = glogger.getLogger("frontend")

local basalt = require("/basalt")

local itemCache = {}

-- the same as above but uses the itemcache variable. Stores the item data in the item cache and a timestamp. If it is older than 5 seconds then it updates it.
local function checkFilter(item, filters)
    --logger.log(0,"Checking item: "..textutils.serialise(item))
    local o = true
    for k, v in pairs(filters) do
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
        itemCache[rid].time = os.time() - 10
    end

    return itemCache[rid].count
end

local function stockUpdate(rid, id, filter)
    if itemCache[rid] == nil then
        itemCache[rid] = {}
        itemCache[rid].count = 0
        itemCache[rid].time = os.time() - 10
    end

    local count = 0
    local rawNames = peripheral.getNames()
    for k, v in ipairs(rawNames) do
        if string.match(v, "chest") == "chest" or string.match(v, "ender_storage") == "ender_storage" then
            local chest = peripheral.wrap(v)
            for kk, vv in pairs(chest.list()) do
                if vv.name == id and checkFilter(chest.getItemDetail(kk), filter) then
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

function mysplit (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function showError(err)
    logger.log(1, "Critical error: " .. err)
    local monitor = peripheral.find("monitor")
    monitor.setBackgroundColor(0x100)
    monitor.setTextColor(0x4000)
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("The shop had an error")
    monitor.setCursorPos(1, 2)
    monitor.write(err)
end

local fis = false

function frontend(layout)
    local itemCache = {}
    local yy = 0


    local monitor = peripheral.find("monitor")
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    monitor.setTextScale(0.5)
    local main = basalt.addMonitor()
    main:setMonitor(monitor)

    function getxp(vav)

        if vav.align == nil then
            vav.align = "left"
        end
        if vav.align == "left" then
            return 1
        elseif vav.align == "center" then
            return "parent.w/2 - self.w/2"
        elseif vav.align == "right" then
            return "parent.w - self.w"
        end
    end



    local function esc(x)
        return (x:gsub('%%', '%%%%'):gsub('^%^', '%%^'):gsub('%$$', '%%$'):gsub('%(', '%%('):gsub('%)', '%%)'):gsub('%.', '%%.'):gsub('%[', '%%['):gsub('%]', '%%]'):gsub('%*', '%%*'):gsub('%+', '%%+'):gsub('%-', '%%-'):gsub('%?', '%%?'))
    end

    function rebuildUi()
        main:remove()
        main = basalt.addMonitor()
        main:setMonitor(monitor)
        --main:setSize(main:getWidth()+2, main:getHeight())
        local yy_btm = main:getHeight()+1

        function getyp(vav, he)
            if vav.align_h == nil then
                vav.align_h = "top"
            end
            if vav.align_h == "top" then
                return yy
            elseif vav.align_h == "center" then
                return "math.floor(parent.h/2 - self.h/2)"
            elseif vav.align_h == "bottom" then
                return yy_btm - he
            end
        end

        for k, v in ipairs(layout) do
            if v.text then
                -- check if the text contains things like {Shop-Name} {Shop-Description} etc.
                -- the text may have a "-" symbol too. Make it so that it won't confuse the pattern
                local text = v.text
                for kk, vv in pairs(config) do
                    --print("{"..kk.."}")
                    text = string.gsub(text, "{" .. esc(kk) .. "}", vv)
                end
                --print(text)
                v.text = text
            end
        end

        local objects = {}

        local bg = colors.gray
        local fge = colors.white

        for k, v in ipairs(layout) do
            yy = yy + 1
            if v.type == "Header" then

                print(fge, colors.white)
                local laba = main:addLabel()
                laba:setForeground(fge)
                if v.background then
                    laba:setBackground(v.background)
                else
                    laba:setBackground(bg)
                end
                --
                laba:setText(v.text)
                laba:setFontSize(2)
                laba:setSize(laba:getWidth(), 3)



                laba._i = k

                if v.background then

                    local p = main:addPane()
                    p:setBackground(v.background)
                    p:setSize(main:getWidth()+1, laba:getHeight()+2)
                    p:setPosition("parent.w/2 - self.w/2", getyp(v, laba:getHeight())-1)

                    laba:setBackground(v.background)
                    laba:setPosition("parent.w/2 - self.w/2", getyp(v, laba:getHeight()))

                  --  logger.log(0, "tux")
                else
                    laba:setBackground(bg)
                    laba:setPosition("parent.w/2 - self.w/2", getyp(v, laba:getHeight()))

                end
                --laba:setForeground(fg)


                yy = yy + 3
                if v.align_h == "bottom" then
                    for kk,vv in pairs(objects) do
                        if vv.layoutobj.align_h == "bottom" then
                            if vv.obj.getHeight == nil then
                                for kkk, vvv in ipairs(vv.obj) do
                                    vvv:setPosition(vvv:getX(), vvv:getY() - laba:getHeight())
                                end
                            else
                                vv.obj:setPosition(vv.obj:getX(), vv.obj:getY() - laba:getHeight())
                            end
                        end
                    end
                end
                table.insert(objects, {
                    layoutobj=v,
                    obj=laba
                })
            elseif v.type == "Text" then

                local function getxp(vav)
                    if vav.align == nil then
                        vav.align = "left"
                    end
                    if vav.align == "left" then
                        return 1
                    elseif vav.align == "center" then
                        return "parent.w/2 - ((self.w-2)/2)"
                    elseif vav.align == "right" then
                        return "parent.w - (self.w-2)"
                    end
                end

                local laba = main:addLabel()

                laba:setFontSize(1)
                laba:setSize(#v.text+1, 1)
                laba:setText(v.text)
                laba:setPosition(getxp(v), getyp(v, laba:getHeight()))
                laba:setForeground(fge)
                laba:setBackground(bg)
                laba._i = k
                if v.align_h == "bottom" then
                    for kk,vv in pairs(objects) do
                        if vv.layoutobj.align_h == "bottom" then
                            if vv.obj.getHeight == nil then
                                for kkk, vvv in ipairs(vv.obj) do
                                    vvv:setPosition(vvv:getX(), vvv:getY() - laba:getHeight())
                                end
                            else
                                vv.obj:setPosition(vv.obj:getX(), vv.obj:getY() - laba:getHeight())
                            end
                        end
                    end
                end
                table.insert(objects, {
                    layoutobj=v,
                    obj=laba
                })
            elseif v.type == "SellTable" then
                local lists = {}
                local xx = 1
                local overallWidther = 0
                for i, j in ipairs(v.columns) do
                    -- set xstart and xend. Do almost the same as in the first pass.
                    if j.width == nil then
                        j.width = main:getWidth() / 4
                    end
                    overallWidther = overallWidther + j.width
                end
                local multiplierer = (main:getWidth() - 1) / overallWidther
                for kk, vv in ipairs(v.columns) do
                    local function getxp(vav)
                        if vav.align == nil then
                            vav.align = "left"
                        end
                        if vav.align == "left" then
                            return xx
                        elseif vav.align == "center" then
                            return "parent.w/2 - self.w/2"
                        elseif vav.align == "right" then
                            return "parent.w - self.w"
                        end
                    end
                    local list = main:addList()
                    local sisi = math.ceil(((vv.width or (main:getWidth() / 4))) * multiplierer)
                    list:setSize(sisi, 1)
                    list:setPosition(xx, yy)
                    list._i = kk
                    xx = math.ceil(xx + ((vv.width or (main:getWidth() / 4))) * multiplierer)
                    list:addItem(vv.name .. string.rep(" ", sisi - #vv.name), v.colors.header, colors.white)
                    list:setSelectionColor(colors.gray, colors.white)
                    list:selectItem(nil)
                    table.insert(lists, list)
                end
                local koptat = 0
                for kk, vv in ipairs(config.Items) do


                    --print(v.xend-v.xstart)




                    for i, j in ipairs(v.columns) do

                        local text = j.text
                        text = string.gsub(text, "{name}", vv.Name)
                        text = string.gsub(text, "{price}", vv.Price)
                        text = string.gsub(text, "{stock}", stockLookup(vv.rawId, vv.Id, vv.filters))
                        text = string.gsub(text, "{alias}", vv.Alias or "")

                        lists[i]:addItem(text .. string.rep(" ", lists[i]:getWidth() - #text), koptat % 2 == 0 and v.colors.background[2] or v.colors.background[1], koptat % 2 == 0 and v.colors.text[2] or v.colors.text[1])
                        lists[i]:setSize(lists[i]:getWidth(), lists[i]:getHeight() + 1)
                        --rint(text)
                    end
                    koptat = koptat + 1

                end
                -- add a element to the bottom of the lists with the header color
                for kk, vv in ipairs(lists) do
                    vv:addItem(string.rep(" ", vv:getWidth()), v.colors.header, colors.white)
                    vv:setSize(vv:getWidth(), vv:getHeight() + 1)
                end
                yy = yy + lists[1]:getHeight() - 1
                if v.align_h == "bottom" then
                    for kk,vv in pairs(objects) do
                        if vv.layoutobj.align_h == "bottom" then
                            if vv.obj.getHeight == nil then
                                for kkk, vvv in ipairs(vv.obj) do
                                    vvv:setPosition(vvv:getX(), vvv:getY() - laba:getHeight())
                                end
                            else
                                vv.obj:setPosition(vv.obj:getX(), vv.obj:getY() - laba:getHeight())
                            end
                        end
                    end
                end
                table.insert(objects, {
                    layoutobj=v,
                    obj=lists
                })
            elseif v.type == "background" then
                main:setBackground(v.bg)
                bg = v.bg
                fge = tonumber(v.text)
            end


        end
    end

    parallel.waitForAny(function()
        while true do
            rebuildUi()
            basalt.drawFrames()
            os.sleep(1)
            yy = 0
        end
    end, function()
        while true do
            os.sleep(2)
            for k, v in ipairs(config.Items) do
                stockUpdate(v.rawId, v.Id, v.filters)
            end
        end
    end)


end

function start()
    local layout = require("../layout")
    _G.kristedData.layout = layout
    local updater = require("../frontend-modules/updater")
    parallel.waitForAny(function()
        local stat, err = pcall(updater, layout)
        if not stat then
            showError(err)
        end
    end, function()
        local stat, err = pcall(frontend, layout)
        if not stat then
            showError(err)
        end
    end)
end

return start