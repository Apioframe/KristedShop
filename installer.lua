local args = {...}

local text = [[
     _  __     _     _           _
    | |/ /    (_)   | |         | |
    | ' / _ __ _ ___| |_ ___  __| |
    |  < | '__| / __| __/ _ \/ _` |
    | . \| |  | \__ \ ||  __/ (_| |
    |_|\_\_|  |_|___/\__\___|\__,_|

]]
print(text)
print("Installer")
print("By. VectorTech team (Bagi_Adam, BomberPlayz_)")

local branch = "dev"
local sat,occ = pcall(require, "config")
if sat then
    branch = occ.branch
end

print("Installing version: "..http.get("https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/version.txt").readAll())

print("Checking for old versions...")
if fs.exists("config.lua") then
    print("Older versions found: "..require("config").Version)
end

print("Downloading apis...")
shell.run("rm kristapi.lua")
shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/kristapi.lua kristapi.lua")
--shell.run("rm json.lua")
--shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/json.lua json.lua")
shell.run("rm discordWebhook.lua")
shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/discordWebhook.lua discordWebhook.lua")

print("Downloading modules...")
shell.run("rm module/")
shell.run("mkdir module")
--shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/module/updater.lua module/updater.lua")
shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/module/backend.lua module/backend.lua")
shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/module/frontend.lua module/frontend.lua")
shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/module/dynamicpricing.lua module/dynamicpricing.lua")

print("Downloading frontend-modules")
shell.run("rm frontend-modules/")
shell.run("mkdir frontend-modules")
shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/frontend-modules/updater.lua frontend-modules/updater.lua")

print("Downloading music")
shell.run("rm jingle_3.dfpwm")
shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/jingle_3.dfpwm jingle_3.dfpwm")

print("Downloading main system...")
shell.run("rm main.lua")
shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/main.lua main.lua")

print("Downloading config...")
if fs.exists("config.lua") then
    shell.run("rm configpre.lua")
    shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/config.lua configpre.lua")
    print("Updating config...")
    local oc = require("config")
    local nc = require("configpre")
    for k,v in pairs(nc) do
        if oc[k] == nil then
            oc[k] = v
        end
    end
    oc.Version = nc.Version
    local ncc = fs.open("config.lua", "w")
    ncc.write("return "..textutils.serialise(oc))
    ncc.close()
else
    shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/config.lua config.lua")
end

print("Downloading layout...")
if not fs.exists("layout.lua") then
    shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/"..branch.."/layout.lua layout.lua")
end

print("Downloading the ui...")
shell.run("wget run https://basalt.madefor.cc/install.lua packed")

print("Generating startup...")
local fi = fs.open("startup.lua","w")
fi.write('shell.run("main.lua")')
fi.close()

print("Kristed installed on your system!")
if args[1] == "autostart" then
    shell.run("main")
end