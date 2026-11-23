-- Run as an autorun in a disposable singleplayer client with System Aegis.
if not CLIENT or not Game.IsSingleplayer then return end
local path='LocalMods/System-Aegis/air170-'
local function report(name,fn)
    local ok,err=pcall(fn)
    File.Write(path..name..'.txt',ok and 'PASS' or 'FAIL '..tostring(err))
end
local function run()
    if not Game.RoundStarted then Timer.Wait(run,500);return end
    report('setup',function()
        local owner=assert(Character.Controlled)
        local G=assert(AegisSuit)
        local function item(id) return Item(ItemPrefab.Prefabs[id],owner.WorldPosition,nil) end
        local suit=item('aegisservosuitcoalition')
        local battery=item('batterycell')
        local tank=item('oxygentank')
        local compressor=item('aegiscompressormodule')
        local slots=G.container(suit,1)
        assert(slots.Capacity==6)
        local old=owner.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
        if old then old.Drop(owner) end
        assert(owner.Inventory.TryPutItem(suit,owner,{InvSlotType.OuterClothes}))
        assert(slots.TryPutItem(compressor,4,false,false,owner))
        assert(slots.TryPutItem(tank,5,false,false,owner))
        assert(slots.TryPutItem(battery,0,false,false,owner))
        local full=tank.MaxCondition
        tank.Condition=full*.25
        Timer.Wait(function()
            report('refill',function()
                assert(G.state(suit).open,'test requires a breathable compartment')
                assert(tank.Condition>full*.25 and battery.Condition<battery.MaxCondition)
            end)
            report('tank-only',function()
                local oldAir=G.air
                G.air=function() return {hull=false,wet=true} end
                local ok,err=pcall(function()
                    local before=tank.Condition
                    battery.Condition=0
                    G.breathe(owner,suit,.1)
                    assert(owner.OxygenAvailable==100 and tank.Condition<before)
                    tank.Condition=0;battery.Condition=battery.MaxCondition
                    G.breathe(owner,suit,.1)
                    assert(owner.OxygenAvailable==0 and tank.Condition==0)
                end)
                G.air=oldAir
                assert(ok,tostring(err))
            end)
        end,1500)

        local bot=Character.Create('human',owner.WorldPosition,'aegis-air-native',nil,0,false,true,true,nil,true,false)
        bot.TeamID=owner.TeamID
        bot.AIController.Enabled=true
        local botSuit=item('aegisservosuit')
        local botSlots=G.container(botSuit,1)
        local low=item('oxygentank');low.Condition=low.MaxCondition*.05
        local spare=item('oxygentank')
        local servo=item('aegisservomodulecoalition')
        local impeller=item('aegisimpellermodulehusk')
        local pump=item('aegiscompressormodule')
        local botBattery=item('batterycell')
        assert(bot.Inventory.TryPutItem(botSuit,bot,{InvSlotType.OuterClothes}))
        assert(botSlots.TryPutItem(low,5,false,false,bot))
        for _,part in ipairs({spare,botBattery,servo,impeller,pump}) do
            assert(bot.Inventory.TryPutItem(part,bot,{InvSlotType.Any}))
        end
        Timer.Wait(function()
            report('bot',function()
                assert(bot.IsBot and G.equipped(bot)==botSuit,'bot lost suit')
                assert(botSlots.GetItemAt(5)==spare,'low tank was not replaced')
                assert(botSlots.GetItemAt(0)==botBattery,'battery was not installed')
                assert(botSlots.GetItemAt(2)==servo,'servo was not installed, fetch slot '..tostring(G.state(botSuit).supplySlot))
                assert(botSlots.GetItemAt(3)==impeller,'impeller was not installed')
                assert(botSlots.GetItemAt(4)==pump,'compressor was not installed')
                assert(not low.Removed,'old tank was lost')
            end)
        end,6500)
    end)
end
File.Write(path..'loaded.txt','READY')
Timer.Wait(run,500)
