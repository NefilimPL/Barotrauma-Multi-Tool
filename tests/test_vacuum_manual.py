from lua_support import LuaCase


class VacuumManualTests(LuaCase):
    def test_native_drag_uses_each_inventory_signature_and_parameter_name(self):
        lua_test = '''
            local mod,trailingFlags=...
            package.path=mod..'/?.lua;'..package.path
            package.loaded['AegisVacuum.manual']=nil
            local hooks={};E.CLIENT=true;E.Character={Controlled=owner}
            E.Inventory={DraggingItems={item}};E.PlayerInput={PrimaryMouseButtonReleased=function() return true end}
            G.patch=function(n,c,m,fn,after,types)
                if m=='TryPutItem' then
                    if #types~=8+trailingFlags then error('native method not found') end
                    assert(types[2]=='System.Int32' and types[5]=='Barotrauma.Character')
                    assert(trailingFlags==0 or (types[9]=='System.Boolean' and types[10]=='System.Boolean'))
                end
                hooks[n]=fn
            end
            G.context=function() return ctx end
            local requested
            G.request=function(action,p,target,view) requested=view.targets end
            require('AegisVacuum.manual').install(G,E)
            local inv={GetItemAt=function(i) assert(i==0);return pack end}
            for kind,slot in pairs({character='index',container='i'}) do
                hooks['manual-drag-start']()
                local p=setmetatable({[slot]=0,user=owner,item=item},
                    {__index=function(t,k) error('unknown native argument '..k) end})
                assert(hooks['manual-drag-'..kind](inv,p))
                assert(p.PreventExecution and requested[1]==item.ID)
            end
        '''
        for directory in ('System-Aegis', 'System-Aegis-No-Headsets'):
            for trailing_flags in (0, 2):
                with self.subTest(directory=directory, trailing_flags=trailing_flags):
                    self.lua.execute(lua_test, directory + '/Lua', trailing_flags)

    def setUp(self):
        super().setUp()
        self.lua.execute('''
            local function isType(v,t) return v and v.type==t end
            owner={type='Barotrauma.Character',CanInteractWith=function() return true end}
            pack={ID=1,kind='aegisvacuumpack',Tags='aegis.vacuum.exclude.iron'}
            item={ID=2,kind='iron',ParentInventory={Owner=owner}}
            local items={[2]=item};moved={}
            E={Entity={FindEntityByID=function(id) return items[id] end},LuaUserData={IsTargetType=isType}}
            G={jobs={},pending={},reserved={},patch=function() end,
                is=function(i,k) return i and i.kind==k end,
                safeStorageInput=function() return true end,
                insert=function(p,i,c) moved[#moved+1]=i;return true end}
            require('AegisVacuum.manual').install(G,E)
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
