local dw = {}
--local json = require("json")

dw.sendMessage = function(link, content)
    local da = {
        ["content"]=content
    }
    http.post(link, textutils.serialiseJSON(da), {["Content-Type"]="application/json"})
end

dw.sendEmbed = function(link, title, desc, color, fields)
    --print('{"embeds": [{"title":"'..title..'","description":"'..desc..'","color":"'..color..'","fields":['..fi..']}]}')
    --print(json.decode('{"embeds": [{"title":"'..title..'","description":"'..desc..'","color":"'..color..'","fields":['..fi..']}]}'))

    local da = {
        ["embeds"]={
            {

            }
        }
    }

    if title == nil then
        local data = link
        da.embeds[1] = data
    else
        da = {
            ["embeds"] = {
                {
                    ["title"]=title,
                    ["description"]=desc,
                    ["color"]=color,
                    ["fields"]=fields
                }
            }
        }
    end



    http.post(link, textutils.serialiseJSON(da), {["Content-Type"]="application/json"})
end

dw.sendBuilderEmbed = function()
    local da = {
        ["embeds"] = {
            {
                ["title"] = "",
                ["description"] = "",
                ["color"] = "",
                ["fields"] = {}
            }
        }
    }

    local ret = {

    }

    ret["setTitle"] = function(title)
        da.embeds[1].title = title
        return ret
    end

    ret["setDescription"] = function(desc)
        da.embeds[1].description = desc
        return ret
    end

    ret["setColor"] = function(color)
        da.embeds[1].color = color
        return ret
    end

    ret["addField"] = function()
        local ret2 = ret
        local field = {
            ["name"] = "",
            ["value"] = "",
            ["inline"] = false
        }

        local ret = {}

        ret["setName"] = function(name)
            field.name = name
            return ret
        end

        ret["setValue"] = function(value)
            field.value = value
            return ret
        end

        ret["setInline"] = function(inline)
            field.inline = inline
            return ret
        end

        ret["endField"] = function()
            table.insert(da.embeds[1].fields, field)
            return ret2
        end


        return ret
    end

    ret["send"] = function(link)
        http.post(link, textutils.serialiseJSON(da), {["Content-Type"]="application/json"})

    end


    return ret
end



return dw