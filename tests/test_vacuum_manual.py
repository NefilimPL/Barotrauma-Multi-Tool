from lua_support import LuaCase


class VacuumManualTests(LuaCase):
    def test_native_container_drag_uses_its_actual_parameter_name(self):
        self.lua.execute('''
            local hooks={};E.CLIENT=true;E.Character={Controlled=owner}
            E.Inventory={DraggingItems={item}};E.PlayerInput={PrimaryMouseButtonReleased=function() return true end}
            G.patch=function(n,c,m,fn) hooks[n]=fn end
            G.context=function() return ctx end
            local requested
            G.request=function(action,p,target,view) requested=view.targets end
            require('SalvageVacuum.manual').install(G,E)
            local p=setmetatable({i=0,user=owner,item=item},{__index=function(t,k) error('unknown native argument '..k) end})
            local inv={GetItemAt=function(i) assert(i==0);return pack end}
            assert(hooks['manual-drag-container'](inv,p))
            assert(p.PreventExecution and requested[1]==item.ID)
        ''')

    def setUp(self):
        super().setUp()
        self.lua.execute('''
            local function isType(v,t) return v and v.type==t end
            owner={type='Barotrauma.Character',CanInteractWith=function() return true end}
            pack={ID=1,kind='aegisvacuumpack',Tags='bmt.vacuum.exclude.iron'}
            item={ID=2,kind='iron',ParentInventory={Owner=owner}}
            local items={[2]=item};moved={}
            E={Entity={FindEntityByID=function(id) return items[id] end},LuaUserData={IsTargetType=isType}}
            G={jobs={},pending={},reserved={},patch=function() end,
                is=function(i,k) return i and i.kind==k end,
                safeStorageInput=function() return true end,
                insert=function(p,i,c) moved[#moved+1]=i;return true end}
            require('SalvageVacuum.manual').install(G,E)
            ctx={valid=true,pack=pack,owner=owner}
        ''')

    def test_owned_item_can_be_inserted_despite_automatic_pickup_filter(self):
        self.lua.execute('''
            local ok,n=G.insertBatch(ctx,{2,2,99})
            assert(ok and n==1 and #moved==1 and moved[1]==item)
        ''')

    def test_foreign_locked_reserved_or_busy_items_cannot_move(self):
        self.lua.execute('''
            item.ParentInventory.Owner={type='Barotrauma.Character'}
            assert(not G.insertBatch(ctx,{2}))
            item.ParentInventory.Owner=owner;item.ParentInventory.Locked=true
            assert(not G.insertBatch(ctx,{2}));item.ParentInventory.Locked=false
            G.reserved[item]=true;assert(not G.insertBatch(ctx,{2}));G.reserved[item]=nil
            G.pending[pack]={};assert(not G.insertBatch(ctx,{2}));G.pending[pack]=nil
            G.safeStorageInput=function() return false end;assert(not G.insertBatch(ctx,{2}))
            assert(#moved==0)
        ''')

    def test_failed_insert_preserves_source_without_drop_or_recreation(self):
        self.lua.execute('''
            local original=item.ParentInventory
            G.insert=function() return false end
            assert(not G.insertBatch(ctx,{2}))
            assert(item.ParentInventory==original and not item.Removed)
        ''')

    def test_empty_backpack_retries_after_native_page_spawn_and_reset_cancels_retry(self):
        self.lua.execute('''
            local callback;E.Timer={Wait=function(fn) callback=fn end};G.alive=true
            G.pageSpawning={[pack]=true};G.context=function() return ctx end
            local ready=false
            G.insert=function(p,it) if ready then moved[#moved+1]=it;return true end;return false end
            assert(G.insertBatch(ctx,{2}) and callback,'new pack needs an automatic retry after creating its first page')
            ready=true;G.pageSpawning[pack]=nil;callback();assert(#moved==1)
            moved={};ready=false;G.pageSpawning[pack]=true
            G.insertBatch(ctx,{2});G.clearManual();ready=true;callback()
            assert(#moved==0,'retry survived round reset')
        ''')
