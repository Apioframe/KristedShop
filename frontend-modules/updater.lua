local config, kristapi, dw, glogger = _G.kristedData.config, _G.kristedData.kristapi, _G.kristedData.dw, _G.kristedData.logger

local logger = glogger.getLogger("updater")
local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

function updater(layout)
    if config["Enable-Automatic-Update"] then
        while true do
            local nver = http.get("https://raw.githubusercontent.com/afonya2/KristedShop/"..config.branch.."/version.txt").readAll()
            if config.Version ~= nver then
                logger.log(1,"New version found: "..nver)
                local monitor = peripheral.find("monitor")
                local w,h = monitor.getSize()
                local decoder = dfpwm.make_decoder()

                if speaker ~= nil then
                    for chunk in io.lines("jingle_3.dfpwm", 16 * 1024) do
                        local buffer = decoder(chunk)

                        while not speaker.playAudio(buffer, 1) do
                            os.pullEvent("speaker_audio_empty")
                        end
                    end
                end

                table.insert(layout, 1, {type = "Text", text = "in ?? seconds", align = "right", color=0x4000})
                table.insert(layout, 1, {type = "Text", text = "Automatic update", align = "right", color=0x4000})

                for i=60,1,-1 do
                    layout[2].text = "in "..i.." seconds"
                    os.sleep(1)
                end
                layout[2].text = "now!"

                local fi = fs.open("startup.lua","w")
                fi.write('local monitor = peripheral.find("monitor")\n')
                fi.write('monitor.setBackgroundColor(0x100)\n')
                fi.write('monitor.setTextColor(0x4000)\n')
                fi.write('monitor.clear()\n')
                fi.write('monitor.setCursorPos(1,1)\n')
                fi.write('monitor.write("The shop is currently updating...")\n')

                fi.write('shell.run("rm installer.lua")\n')
                fi.write('shell.run("wget https://raw.githubusercontent.com/afonya2/KristedShop/'..config.branch..'/installer.lua")\n')
                fi.write('shell.run("installer autostart")')
                fi.close()
                logger.log(1,"Updater updated, restarting so the updated updater can update the shop system")
                shell.run("reboot")
            end
            os.sleep(60)
        end
    else
        logger.log(2, "Auto updater is disabled, not running!")
        while true do
            os.sleep(0)
        end
    end
end

return updater