-- Disposable client only: real driver, real audio tags, no actual power cost.
assert(CLIENT)
local G=BMTHeadsets
local character=Character.Controlled
local item=G.equipped(character)
assert(item,'equip the test headset first')
local before=G.energy(item)
local emit=G.emit
local warnings={}
G.emit=function(c,device,kind,joint)
    if c==character and device==item and kind=='warning' then warnings[#warnings+1]=G.energy(item) end
    return emit(c,device,kind,joint)
end
local ok,err=pcall(function()
    G.state(item).warningTier=nil
    for _,energy in ipairs({20,10,0}) do
        G.setEnergy(item,energy);G.checkPower(character,item)
        assert(math.abs(G.energy(item)-energy)<.0001,'alarm consumed power')
    end
    assert(#warnings==3,'missing power alarm')
end)
G.emit=emit;G.setEnergy(item,before)
File.Write('LocalMods/MULTI-TOOL-V2/headset-power-alarms-results.txt',
    ok and 'PASS native low/critical/empty alarm driver at 20/10/0 percent, no power cost' or 'FAIL '..tostring(err))
