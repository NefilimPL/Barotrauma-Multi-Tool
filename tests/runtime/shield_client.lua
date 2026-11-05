-- TEST ONLY: autorun on an isolated client, with a real graphics device.
if not CLIENT then return end
Timer.Wait(function()
    local gun,batch
    local G=BMTCombat
    local previous=G.authoritative
    local remote,cast=G.remote,G.cast
    local ok,err=pcall(function()
        LuaUserData.RegisterType('Barotrauma.GameMain')
        LuaUserData.RegisterType('Microsoft.Xna.Framework.Graphics.GraphicsDevice')
        local gm=LuaUserData.CreateStatic('Barotrauma.GameMain')
        local SB=LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.SpriteBatch')
        local Blend=LuaUserData.CreateStatic('Microsoft.Xna.Framework.Graphics.BlendState')
        local Sort=LuaUserData.CreateEnumTable('Microsoft.Xna.Framework.Graphics.SpriteSortMode')
        batch=SB(gm.Instance.GraphicsDevice)
        local cam=gm.GameScreen.Cam
        gun=Item(ItemPrefab.Prefabs['combatmultitool'],Vector2.Zero,nil)
        assert(Entity.FindEntityByID(gun.ID)==gun,'native entity lookup failed')
        G.authoritative=false
        for _,dir in ipairs({1,-1}) do
            for _,angle in ipairs({0,math.pi/2,math.pi,-math.pi/2}) do
                gun.body.Dir=dir
                gun.body.SetTransform(ConvertUnits.ToSimUnits(cam.WorldViewCenter),angle)
                gun.body.UpdateDrawPosition(false)
                local expected=gun.body.DrawPosition
                local rays=0
                G.cast=function(a)
                    assert(math.abs(a.x-expected.X)<.01 and math.abs(a.y-expected.Y)<.01,
                        'shield used stale network coordinates instead of the displayed weapon')
                    rays=rays+1
                end
                G.remote={received=G.now,rings={},shields={{id=gun.ID,x=-10000,y=-10000,angle=0,energy=100}}}
                batch.Begin(Sort.Deferred,Blend.NonPremultiplied)
                local drawn,drawError=pcall(G.draw,batch,cam)
                batch.End()
                assert(drawn,drawError)
                assert(rays==41,'native shield drawing did not check all arc points and texture strips')
            end
        end
    end)
    G.authoritative=previous;G.remote=remote;G.cast=cast
    if gun and not gun.Removed then G.states[gun]=nil;gun.Remove() end
    if batch then batch.Dispose() end
    local result=ok and 'PASS native entity lookup and GPU shield drawing: 4 angles x 2 facings, stale snapshot position ignored'
        or 'FAIL '..tostring(err)
    File.Write('LocalMods/MULTI-TOOL-V2/shield-client-results.txt',result)
    print('[BMT SHIELD CLIENT] '..result)
end,8000)
