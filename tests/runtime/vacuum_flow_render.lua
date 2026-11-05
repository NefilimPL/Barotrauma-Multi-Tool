assert(CLIENT and Game.IsSingleplayer and Vacuum134 and Vacuum134.nozzle)
local R,G=Vacuum134,BMTVacuum
G.closePanel()
local original=G.context
G.context=function(item,character)
    local ctx=original(item,character)
    if item==R.nozzle then ctx.aim=true end
    return ctx
end
Hook.Add('think','bmt.test.flow',function()
    G.states[R.nozzle]=G.states[R.nozzle] or {}
    G.states[R.nozzle].usedAt=G.now
end)
Timer.Wait(function()
    R.check('native GPU draws interpolated suction and moving streaks without render errors',function()
        assert(not G.visualError,tostring(G.visualError))
        assert(G.suctionActive(R.nozzle,G.states[R.nozzle]))
    end)
    Hook.Remove('think','bmt.test.flow');G.context=original;G.clearAudio()
    local palette={'copper','zinc','lead','carbon','aluminium','titanium','plastic','rubber','organicfiber',
        'morphine','opium','antibiotics','chlorine','sodium','potassium','sulphur','phosphorus','lithium',
        'uranium','thorium','calcium','silicon','ethanol','screwdriver','batterycell','redwire','bluewire'}
    for _,kind in ipairs(palette) do
        local ok,p=pcall(function() return ItemPrefab.Prefabs[kind] end)
        if ok and p then
            local item=Item(p,R.character.WorldPosition,nil)
            assert(G.insert(R.pack,item,R.character))
        end
    end
    G.openPanel(R.pack)
end,2500)
