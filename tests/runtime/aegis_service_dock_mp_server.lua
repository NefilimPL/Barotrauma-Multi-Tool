assert(SERVER and Game.RoundStarted)
local G=AegisSuit;local B=ServoServiceMP;local c=B.wearer
local P='aegis.servo.service.dock';local U=require('AegisCombat.util');local R={};ServoDockMP=R
local function spawn(id,p,fn) Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.Prefabs[id],p,c.Submarine,nil,nil,fn) end
local function pin(item,name) local result;U.each(item.GetComponentString('ConnectionPanel').Connections,function(v) if v.Name==name then result=v end end);return assert(result) end
Networking.Receive(P..'.ready',function(_,client)
    if client~=B.client then return end
    G.setMode(B.suit,'off',c);local s=G.state(B.suit);s.sonar=false
    spawn('divingsuitlocker',c.Position+Vector2(-135,10),function(rack)
        R.rack=rack;assert(rack.OwnInventory.TryPutItem(B.suit,c));B.cell.Condition=20
        spawn('battery',c.Position+Vector2(-250,0),function(battery)
            R.battery=battery;local storage=battery.GetComponentString('PowerContainer');storage.Charge=1000;storage.RechargeSpeed=0
            spawn('redwire',c.Position,function(item)
                R.wire=item.GetComponentString('Wire');local a,b=pin(battery,'power_out'),pin(rack,'power_in')
                assert(a.TryAddLink(R.wire) and b.TryAddLink(R.wire));assert(R.wire.Connect(a,0,false,false) and R.wire.Connect(b,1,false,false))
                Timer.Wait(function()
                    local ok,detail=pcall(function()
                        assert(rack.GetComponentString('Powered').Voltage>.1 and B.cell.Condition>20)
                        return 'voltage='..rack.GetComponentString('Powered').Voltage..' source='..B.cell.Condition
                    end)
                    local result=(ok and 'PASS ' or 'FAIL ')..tostring(detail);print('[SERVO DOCK MP] '..result)
                    File.Write('LocalMods/System-Aegis/servo-service-dock-mp-server.txt',result)
                    local m=Networking.Start(P..'.check');m.WriteUInt16(rack.ID);m.WriteUInt16(B.suit.ID);m.WriteUInt16(B.cell.ID);Networking.Send(m,client.Connection)
                end,5000)
            end)
        end)
    end)
end)
