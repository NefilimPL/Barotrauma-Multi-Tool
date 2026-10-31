-- Isolated client only; install as zz_headset_client_probe.lua in its Autorun.
if not CLIENT then return end
Timer.Wait(function()
    local batch
    local ok,err=pcall(function()
        local G=BMTHeadsets
        assert(G and G.drawEffects,'headset client did not initialize')
        LuaUserData.RegisterType('Barotrauma.GameMain')
        LuaUserData.RegisterType('Microsoft.Xna.Framework.Graphics.GraphicsDevice')
        local gm=LuaUserData.CreateStatic('Barotrauma.GameMain')
        local SB=LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.SpriteBatch')
        local Blend=LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.BlendState')
        local Sort=LuaUserData.CreateEnumTable('Microsoft.Xna.Framework.Graphics.SpriteSortMode')
        batch=SB(gm.Instance.GraphicsDevice)
        for _,tag in ipairs({'high','low','critical','empty'}) do
            local p=gm.SoundManager.ListenerPosition
            local channel=SoundPlayer.PlaySound('aegis_headset_'..tag,Vector2(p.X,p.Y))
            assert(channel,'missing native audio tag '..tag);channel.Dispose()
        end
        local cam=gm.GameScreen.Cam
        local view=cam.WorldView
        local x,y=view.X+view.Width/2,view.Y-view.Height/2
        local char={ID=65000,WorldPosition=Vector2(x,y),IsDead=false,Removed=false,
            AnimController={Limbs={{WorldPosition=Vector2(x-10,y-40)},{WorldPosition=Vector2(x+10,y+40)}}}}
        local cell={Condition=100,MaxCondition=100,HasTag=function(t) return t=='mobilebattery' end}
        local item={OwnInventory={GetItemAt=function() return cell end}}
        for _,energy in ipairs({100,30,10,0}) do
            G.now=G.now+1;cell.Condition=energy
            G.emit(char,item,'hit')
            for i=1,35 do
                batch.Begin(Sort.Deferred,Blend.NonPremultiplied)
                G.drawEffects(batch,cam)
                batch.End();G.updateEffects(.02)
            end
        end
        for _,id in ipairs({'aegisheadset','aegisheadsetmk2'}) do
            local device=Item(ItemPrefab.Prefabs[id],Vector2.Zero,nil)
            batch.Begin(Sort.Deferred,Blend.NonPremultiplied)
            device.Sprite.Draw(batch,Vector2(300,300),Color.White,0,.04)
            batch.End();device.Remove()
        end
        G.clearEffects();batch.Dispose();batch=nil
        assert(not G.visualError,G.visualError)
    end)
    if batch then pcall(function() batch.End();batch.Dispose() end) end
    File.Write('LocalMods/MULTI-TOOL-V2/headset-client-results.txt',
        ok and 'PASS native GPU shield shimmer 4 power levels x 35 frames; both equipment textures; 4 spatial audio channels' or 'FAIL '..tostring(err))
    print('[HEADSET CLIENT] '..(ok and 'PASS' or tostring(err)))
end,8000)
