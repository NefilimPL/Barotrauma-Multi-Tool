-- Disposable singleplayer client only; never ship in the mod.
if not CLIENT then return end
File.Write('LocalMods/MULTI-TOOL-V2/vacuum-client-results.txt','WAIT for round')
local function begin()
    if not Game.RoundStarted or not Submarine.MainSub then Timer.Wait(begin,1000);return end
    local rows={}
    local function check(name,fn)
        local ok,err=pcall(fn)
        rows[#rows+1]=(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))
        print('[VACUUM CLIENT] '..rows[#rows])
        File.Write('LocalMods/MULTI-TOOL-V2/vacuum-client-results.txt',table.concat(rows,'\n'))
    end
    local G=BMTVacuum
    local room;for h in Hull.HullList do if h.Submarine==Submarine.MainSub then room=h;break end end
    local c=Character.Create('human',room.WorldPosition,'vacuum-client',nil,0,false,true,true,nil,true,false)
    c.AIController.Enabled=false;c.GodMode=true
    c.TeamID=CharacterTeamType.Team1
    for other in Character.CharacterList do if other.AIController then other.AIController.Enabled=false end end
    Character.Controlled=c
    local function create(id) return Item(ItemPrefab.Prefabs[id],room.WorldPosition,nil) end
    local vacuum,pack,battery,page=create('aegisvacuum'),create('aegisvacuumpack'),create('batterycell'),create('aegisvacuumpage')
    assert(c.Inventory.TryPutItem(vacuum,c,{InvSlotType.RightHand+InvSlotType.LeftHand}))
    assert(c.Inventory.TryPutItem(pack,c,{InvSlotType.Bag}))
    assert(vacuum.OwnInventory.TryPutItem(battery,0,false,false,c))
    assert(pack.OwnInventory.TryPutItem(page,c))
    assert(G.insert(pack,create('wrench'),c))
    assert(G.insert(pack,create('iron'),c))
    _G.VacuumClientTest={c=c,vacuum=vacuum,pack=pack,battery=battery}
    check('client bootstrap and battery placement',function()
        assert(G and G.draw and G.context(vacuum).valid)
        assert(G.source(vacuum)==battery)
    end)
    check('real GUI panel, localized rows and search',function()
        local frame=G.openPanel(vacuum)
        assert(frame and frame.Visible)
        G.onSnapshot(G.snapshot(G.context(vacuum),{page=0,search=''}))
        G.updateClient(1/60)
    end)
    Timer.Wait(function()
        check('GPU draws backpack, hose and all 16 suction frames',function()
            LuaUserData.RegisterType('Barotrauma.GameMain')
            LuaUserData.RegisterType('Microsoft.Xna.Framework.Graphics.GraphicsDevice')
            local gm=LuaUserData.CreateStatic('Barotrauma.GameMain')
            local SB=LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.SpriteBatch')
            local Blend=LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.BlendState')
            local Sort=LuaUserData.CreateEnumTable('Microsoft.Xna.Framework.Graphics.SpriteSortMode')
            local batch=SB(gm.Instance.GraphicsDevice)
            local ranged=require('CombatTool.util').component(vacuum,'RangedWeapon')
            local now=G.now
            c.SetInput(InputType.Aim,false,true)
            ranged.Use(1/60,c)
            for i=0,15 do
                G.now=now+i/16
                G.states[vacuum].usedAt=G.now
                batch.Begin(Sort.Deferred,Blend.NonPremultiplied)
                local ok,err=pcall(G.draw,batch,gm.GameScreen.Cam)
                batch.End();assert(ok,err)
            end
            G.now=now;batch.Dispose()
            assert(not G.visualError,G.visualError)
        end)
        File.Write('LocalMods/MULTI-TOOL-V2/headset-capture.request',
            'F:/_Github/Barotrauma-Multi-Tool/.runtime/vacuum-client-preview.png')
    end,1500)
end
Timer.Wait(begin,8000)
