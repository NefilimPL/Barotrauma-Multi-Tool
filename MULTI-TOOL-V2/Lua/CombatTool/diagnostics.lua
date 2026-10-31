local U=require('CombatTool.util')
local M={}
function M.install(G,E)
    local name='aegis_status'
    function G.printStatus()
        E.print('[Aegis] authority='..tostring(G.authoritative)..' render='..tostring(G.visualError or 'OK')
            ..' rings='..tostring(G.rings and #G.rings or 0))
        local count=0
        for item,s in pairs(G.states) do
            if not item.Removed and count<16 then
                count=count+1
                local ctx=G.context(item)
                E.print('[Aegis] ID='..item.ID..' mode='..tostring(ctx.mode)..' valid='..tostring(ctx.valid)
                    ..' aim='..tostring(ctx.aim)..' damage='..tostring(ctx.damage)..' bot='..tostring(ctx.bot)
                    ..' shield='..tostring(s.shield~=nil))
                local slots={}
                for slot=0,0 do
                    local source=G.source(item,slot)
                    slots[#slots+1]='slot'..(slot+1)..'='..(source and
                        U.itemId(source.item)..':'..string.format('%.2f',source.condition) or 'empty/unsupported')
                end
                E.print('[Aegis] '..table.concat(slots,' '))
                local container=U.component(item,'ItemContainer')
                local cell=E.ItemPrefab.Prefabs['batterycell']
                if container and cell then
                    E.print('[Aegis] batterycell allowed='..tostring(container.CanBeContained(cell,0)))
                end
            end
        end
        if count==0 then E.print('[Aegis] No combat multitool loaded.') end
    end
    E.Game.AddCommand(name,'Print Aegis mode, power, rendering and battery restrictions.',G.printStatus)
    function G.disposeDiagnostics() E.Game.RemoveCommand(name) end
end
return M
