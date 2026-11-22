-- Disposable singleplayer client fixture. Never ship this file.
if not CLIENT then return end
local path='LocalMods/System-Aegis/'
File.Write(path..'ui161-v161-boot.txt','AUTORUN READY')
local P={}
Aegis161Probe=P
local function write(name,value) File.Write(path..name,tostring(value)) end
local function check(name,fn)
    local ok,err=pcall(fn)
    write('ui161-v161-'..name..'.txt',ok and 'PASS' or 'FAIL '..tostring(err))
    return ok
end
function P.run()
    if not Game.RoundStarted then Timer.Wait(P.run,500);return end
    local ok,err=pcall(function()
        assert(AegisSuit and AegisHUD and AegisCombat,'systems missing')
        local c=assert(Character.Controlled,'no controlled character')
        P.character=c;c.GodMode=true
        for _,slot in ipairs({InvSlotType.OuterClothes,InvSlotType.RightHand,InvSlotType.LeftHand}) do
            local item=c.Inventory.GetItemInLimbSlot(slot)
            if item then item.Drop(c) end
        end
        local function item(id) return Item(ItemPrefab.Prefabs[id],c.WorldPosition,nil) end
        P.suit=item('aegisservosuitcoalition');P.gun=item('aegiscombattool')
        P.composite=item('aegiscompositetool');P.pack=item('aegisvacuumpack')
        P.battery=item('batterycell');P.battery.Condition=0
        P.gunBattery=item('batterycell');P.cartridge=item('aegisshieldmodule')
        assert(c.Inventory.TryPutItem(P.suit,c,{InvSlotType.OuterClothes}))
        assert(c.Inventory.TryPutItem(P.gun,c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
        local inv=AegisSuit.container(P.suit,1)
        assert(inv.TryPutItem(P.battery,0,false,false,c))
        assert(inv.TryPutItem(item('aegisservomodulecoalition'),2,false,false,c))
        assert(inv.TryPutItem(item('aegisimpellermodulecoalition'),3,false,false,c))
        assert(P.gun.OwnInventory.TryPutItem(P.gunBattery,0,false,false,c))
        assert(P.gun.OwnInventory.TryPutItem(P.cartridge,1,false,false,c))
        c.Inventory.TryPutItem(P.pack,c,{InvSlotType.Bag})
        Timer.Wait(function()
            check('combined',function()
                AegisHUD.setOpen(true);AegisHUD.update(1/60)
                assert(AegisHUD.panel.Visible and AegisHUD.toolHost.Visible and AegisHUD.armHost.Visible)
                assert(AegisSuit.panel.RectTransform.Parent==AegisHUD.armHost.RectTransform)
                assert(tostring(AegisHUD.status.Text):find('/5',1,true))
            end)
            local H=AegisHUD
            check('modes',function()
                for _,mode in ipairs({'cut','extinguish','combat','weld'}) do
                    H.buttons[mode].OnClicked.Invoke(H.buttons[mode],nil)
                    H.update(1/60)
                    assert(H.buttons[mode].Selected,'selection '..mode)
                end
            end)
            check('collapse',function()
                H.hideButton.OnClicked.Invoke(H.hideButton,nil);H.update(1/60)
                assert(H.tab.Visible and not H.panel.Visible)
                H.tab.OnClicked.Invoke(H.tab,nil);H.update(1/60)
                assert(H.toolHost.Visible and H.armHost.Visible)
            end)
            check('suit-only',function()
                P.gun.Drop(c);H.update(1/60)
                assert(H.armHost.Visible and not H.toolHost.Visible)
            end)
            check('composite-single-hand',function()
                assert(c.Inventory.TryPutItem(P.composite,c,{InvSlotType.RightHand}))
                H.update(1/60)
                assert(H.armHost.Visible and H.toolHost.Visible and H.item==P.composite)
                P.composite.Drop(c)
                assert(c.Inventory.TryPutItem(P.gun,c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
                H.update(1/60)
            end)
            local ticks=0
            local function stress()
                ticks=ticks+1
                P.battery.Condition=ticks%2==1 and 100 or 0
                if ticks<40 then Timer.Wait(stress,150) else
                    P.battery.Condition=100
                    check('light-power-cycles',function()
                        local state=AegisSuit.state(P.suit)
                        AegisSuit.updateLights(state,false)
                        assert(state.lights.helmet.Enabled and state.lights.helmet.Range==650)
                        assert(state.lights.tool.Range>0)
                    end)
                    write('ui161-v161-ready.txt','READY')
                end
            end
            stress()
            local function commands()
                local command=path..'ui161-command.lua'
                if File.Exists(command) then
                    local code=File.Read(command);File.Delete(command)
                    local ok,err=pcall(function() assert(load(code))() end)
                    if not ok then write('ui161-v161-command-error.txt',err) end
                end
                Timer.Wait(commands,300)
            end
            commands()
        end,1500)
    end)
    if not ok then write('ui161-setup.txt','FAIL '..tostring(err)) end
end
P.run()
