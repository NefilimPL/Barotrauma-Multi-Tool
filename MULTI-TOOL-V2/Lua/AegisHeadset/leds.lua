local U=require('CombatTool.util')
local M={}
-- Lens centres measured in the unedited 1254px artwork.
local pixels={aegisheadset={{231.5,819.2}},aegisheadsetmk2={{319.5,631.1},{246.8,782.6},{316.7,940.7}}}
function M.positions(E,character,item)
    local lenses=pixels[U.itemId(item)]
    if not lenses or not character.AnimController then return {} end
    local head
    U.each(character.AnimController.Limbs,function(limb)
        if not limb.IsSevered and limb.type==E.LimbType.Head then head=limb end
    end)
    if not head or not head.body then return {} end
    local worn
    U.each(head.WearingItems,function(sprite)
        if sprite.WearableComponent and sprite.WearableComponent.Item==item then worn=sprite end
    end)
    if not worn or not worn.Sprite then return {} end
    if worn.CanBeHiddenByOtherWearables then
        local hidden=false
        U.each(head.WearingItems,function(sprite)
            if sprite~=worn and sprite.HideOtherWearables then hidden=true end
        end)
        if hidden then return {} end
    end
    local params=head.Params
    local source=worn.Sprite.SourceRect
    local origin=worn.InheritOrigin and head.ActiveSprite.Origin or worn.Sprite.Origin
    local ox,oy=origin.X,origin.Y
    local facing=head.body.Dir<0 and -1 or 1
    if not worn.InheritOrigin and facing<0 then ox=source.Width-ox end
    local flipX=facing<0
    if params.MirrorHorizontally then flipX=not flipX end
    local scale=worn.Scale
    if worn.InheritScale then
        if not worn.IgnoreTextureScale then scale=scale*head.TextureScale end
        if not worn.IgnoreLimbScale then scale=scale*params.Scale end
        if not worn.IgnoreRagdollScale then scale=scale*character.AnimController.RagdollParams.LimbScale end
    end
    local angle=-head.body.DrawRotation-worn.Rotation*facing
    local cos,sin=math.cos(angle),math.sin(angle)
    local centre=head.body.DrawPosition
    local result={}
    for _,lens in ipairs(lenses) do
        local x=(flipX and source.Width-lens[1] or lens[1])-ox
        local y=(params.MirrorVertically and source.Height-lens[2] or lens[2])-oy
        x,y=x*scale,y*scale
        result[#result+1]={x=centre.X+x*cos-y*sin,y=centre.Y-x*sin-y*cos,scale=scale/.035}
    end
    return result
end
return M
