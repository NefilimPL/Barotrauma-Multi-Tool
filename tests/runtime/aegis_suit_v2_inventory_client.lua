-- Client inventory action/replication probe, never package.
local G=AegisSuit
local c=Character.Controlled;local suit=G.equipped(c)
assert(suit and not G.authoritative)
G.requestMode(suit,'off')
local function move(slot)
    local item=G.container(suit,1).GetItemAt(slot);assert(item)
    local allowed=slot==1 and {InvSlotType.RightHand,InvSlotType.LeftHand} or {InvSlotType.Any}
    local ok=c.Inventory.TryPutItem(item,c,allowed)
    assert(ok,'client could not extract slot '..slot)
    local m=Networking.Start('aegis.servo.v2.inventory');m.WriteUInt16(suit.ID);m.WriteUInt16(item.ID);m.WriteByte(slot);Networking.Send(m)
    Timer.Wait(function()
        assert(G.container(suit,1).TryPutItem(item,slot,false,false,c),'client could not fill slot '..slot)
        if slot==0 then Timer.Wait(function() move(1) end,600) end
    end,900)
end
move(0)
