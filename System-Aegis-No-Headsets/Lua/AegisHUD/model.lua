local M={}
function M.mode(flags,combat)
    if flags.extinguisher then return 'extinguish' end
    if combat and flags.damage then return 'combat' end
    return flags.cutter and 'cut' or 'weld'
end
function M.layout(tool,suit,width,height)
    local h=math.min(height*.82,tool and suit and 660 or suit and 420 or 240)
    local header=40/h
    local toolH=tool and (suit and .34 or 1-header) or 0
    return {width=math.min(400,width*.34),height=h,header=header,
        toolY=header,toolH=toolH,armY=header+toolH,armH=suit and 1-header-toolH or 0}
end
return M
