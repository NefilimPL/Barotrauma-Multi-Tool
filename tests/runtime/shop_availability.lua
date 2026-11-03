-- Read native loaded prices, availability and stock; no campaign purchases.
LuaUserData.RegisterType('Barotrauma.PriceInfo')
local prices={['wrenchscrewdrivertwoinoneset']=57,['multi-toolset']=1300,
    combatmultitool=2000,aegisheadset=500,aegisheadsetmk2=1000}
local required={'merchantoutpost','merchantcity','merchantresearch','merchantmilitary',
    'merchantmine','merchantengineering','merchantmedical','merchantarmory'}
local rows={}
for id,price in pairs(prices) do
    local ok,err=pcall(function()
        local prefab=ItemPrefab.Prefabs[id]
        assert(prefab and prefab.CanBeBought,'prefab cannot be bought')
        assert(prefab.DefaultPrice.Price==price,'base price '..prefab.DefaultPrice.Price)
        local stores={}
        -- LuaCs marshals this immutable dictionary into a Lua table.
        for store,p in pairs(prefab.GetBuyPricesUnder(0)) do stores[tostring(store)]=p end
        for _,store in ipairs(required) do
            local p=stores[store]
            assert(p and p.CanBeBought and p.MinAvailableAmount>=1,store..' missing price/stock')
            assert(p.Price>0 and p.Price<=2000,store..' price '..p.Price)
        end
    end)
    rows[#rows+1]=(ok and 'PASS ' or 'FAIL ')..id..' base='..price..' stores=8'..(ok and '' or ': '..tostring(err))
    print('[SHOP TEST] '..rows[#rows])
end
File.Write('LocalMods/MULTI-TOOL-V2/shop-results.txt',table.concat(rows,'\n'))
