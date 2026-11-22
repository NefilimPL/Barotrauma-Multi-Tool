local M={}
function M.mode(flags,combat)
    if flags.extinguisher then return 'extinguish' end
    if combat and flags.damage then return 'combat' end
    return flags.cutter and 'cut' or 'weld'
end
function M.layout(tool,suit,width,height)
    local toolHeight=tool and 124 or 0
    local total=28+toolHeight+(suit and 198 or 0)
    local h=math.min(height*.75,total)
    local header=28/total
    local armY=(28+toolHeight)/total
    return {width=math.min(300,width*.32),height=h,header=header,
        toolY=header,toolH=toolHeight/total,armY=armY,armH=suit and 1-armY or 0}
end
return M
