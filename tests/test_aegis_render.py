from lua_support import LuaCase
from pathlib import Path
import xml.etree.ElementTree as ET


class AegisBeamRenderingTests(LuaCase):
    def test_gauss_projectiles_have_larger_sprites_and_bounded_native_effects(self):
        mod = Path(__file__).resolve().parents[1] / 'System-Aegis'
        items = ET.parse(mod / 'aegis_suit.xml').getroot()
        for variant in ('gauss', 'physicorium', 'explosive', 'piercing'):
            with self.subTest(variant=variant):
                bolt = items.find(f"Item[@identifier='aegis{variant}bolt']")
                scale = float(bolt.get('scale'))
                self.assertGreaterEqual(scale, .30)
                self.assertAlmostEqual(scale * float(bolt.find('Body').get('width')), 50 * .18)
                self.assertAlmostEqual(scale * float(bolt.find('Body').get('height')), 4 * .18)
                projectile = bolt.find('Projectile')
                self.assertNotEqual(projectile.get('hitscan'), 'true')
                self.assertGreaterEqual(float(projectile.get('launchimpulse')), 30)
                trail = projectile.find("StatusEffect[@type='OnActive']/ParticleEmitter")
                self.assertIsNotNone(trail)
                self.assertIn(trail.get('particle'), ('ammotrail', 'ammotrailwater'))
                self.assertLessEqual(float(trail.get('particlespersecond')), 30)
                hit = projectile.find("StatusEffect[@type='OnImpact']/ParticleEmitter[@particle='shrapnel']")
                self.assertIsNotNone(hit)

    def test_both_pulse_variants_have_visible_impact_flashes_without_area_damage(self):
        mod = Path(__file__).resolve().parents[1] / 'System-Aegis'
        items = ET.parse(mod / 'aegis_suit.xml').getroot()
        for variant in ('pulse', 'tri'):
            bolt = items.find(f"Item[@identifier='aegis{variant}bolt']")
            flash = bolt.find("Projectile/StatusEffect[@type='OnImpact']/ParticleEmitter[@particle='muzzleflashpulselaser']")
            self.assertIsNotNone(flash)
            self.assertGreaterEqual(float(flash.get('scalemax')), .12)
            self.assertIsNone(bolt.find('.//Explosion'))

    def test_pulse_particle_does_not_shorten_the_ray_with_uniform_scaling(self):
        mod=Path(__file__).resolve().parents[1]/'System-Aegis'
        bolt=ET.parse(mod/'aegis_suit.xml').getroot().find("Item[@identifier='aegispulsebolt']")
        emitter=bolt.find('Projectile/ParticleEmitter')
        self.assertEqual(float(emitter.get('scalemin','1')),1,'native ray length is uniformly shrunk')
        self.assertEqual(float(emitter.get('scalemax','1')),1)
        particle=ET.parse(mod/'aegis_suit_particles.xml').getroot().find(emitter.get('particle'))
        self.assertIsNotNone(particle)
        x,y=map(float,particle.get('startsizemin').split(','))
        self.assertEqual(x,1)
        self.assertLess(y,.4)
        self.assertEqual(particle.find('sprite').get('sourcerect'),'144,440,1,68')

    def setUp(self):
        super().setUp()
        self.lua.execute("""
            sprites={};draws={};lines={}
            local function vec(x,y) return {X=x,Y=y} end
            local color=setmetatable({White={R=255,G=255,B=255,A=255}},
                {__call=function(_,r,g,b,a) return {R=r,G=g,B=b,A=a} end})
            local function makeSprite(path,origin)
                local s={path=path,Origin=origin,SourceRect={Width=512,Height=512}}
                s.Draw=function(batch,p,c,o,r,scale)
                    draws[#draws+1]={path=path,point=p,origin=o,rotation=r,scale=scale,rect=s.SourceRect,color=c}
                end
                s.Remove=function() s.removed=true end
                sprites[#sprites+1]=s;return s
            end
            package.loaded['AegisSuit.lights']={install=function(G)
                G.removeLights=function() end
            end}
            package.loaded['AegisSuit.ui']={install=function(G)
                G.disposeSuitUI=function() end
            end}
            item={};owner={};target={WorldPosition=vec(300,0)}
            state={mode='combat',active=true,target={kind='combat',entity=target,point={x=300,y=0}},
                lastPulse={x=300,y=0},shotTime=1}
            pose={elbow={x=40,y=20},tip={x=80,y=0},muzzle={x=104,y=0},angle=0}
            G={now=1,authoritative=true,states={[item]=state},
                equipped=function() return item end,owner=function() return owner end,
                mount=function() return {x=0,y=0},0,1 end,
                attachment=function() return {x=0,y=0} end,
                toolPose=function() return pose end,
                patch=function(name,class,method,fn) if name=='draw' then draw=fn end end}
            E={Sprite=makeSprite,Vector2=vec,Color=color,printerror=function() end,Rectangle=function(x,y,w,h)
                return {X=x,Y=y,Width=w,Height=h} end,
                GUI={GUI={Canvas={Rect={Width=800,Height=600}},DrawLine=function(...)
                    lines[#lines+1]={...}
                end}}}
            require('AegisSuit.client').install(G,E,'mod')
            cam={WorldToScreen=function() return vec(0,0) end}
            function render()
                draws={};lines={};draw(owner,{spriteBatch={},cam=cam})
                assert(not G.drawError,G.drawError)
            end
        """)

    def test_pulse_snapshot_does_not_overlay_another_beam_on_native_tracer(self):
        self.lua.execute("render();assert(#lines==0,'duplicate custom pulse lines over native tracer')")

    def test_idle_combat_head_is_the_original_pulse_laser_barrel(self):
        self.lua.execute("""
            state.target=nil;state.lastPulse=nil;render()
            local barrel
            for _,d in ipairs(draws) do
                if d.path=='Content/Items/Weapons/Turrets.png' and d.rect.X==779 then barrel=d end
            end
            assert(barrel,'combat head is still the custom claw')
            assert(barrel.rect.Y==592 and barrel.rect.Width==125 and barrel.rect.Height==333)
            assert(barrel.point.X==pose.muzzle.x and barrel.point.Y==-pose.muzzle.y)
            assert(math.abs(barrel.origin.X-52.5)<.001 and math.abs(barrel.origin.Y-46.4)<.001,
                'native barrel firing offset is detached from shared muzzle')
        """)

    def test_tractor_uses_soft_texture_instead_of_three_hard_gui_bars(self):
        self.lua.execute("""
            state.mode='grab';state.target.kind='grab';state.lastPulse=nil;render()
            assert(#lines==0,'hard rectangular tractor bars remain')
            local n=0
            for _,d in ipairs(draws) do
                if d.path=='Content/Particles/ParticleAtlas.png' then n=n+1 end
            end
            assert(n>0,'no soft textured tractor beam')
        """)

    def test_switching_off_does_not_leave_a_custom_red_flash_behind(self):
        self.lua.execute("""
            state.mode='off';state.target=nil;state.active=false;render()
            assert(#lines==0,'old shot snapshot draws ghost beam after switching off')
        """)

    def test_failed_draw_does_not_hide_other_suits_and_recovers_after_camera_fault(self):
        self.lua.execute("""
            local second={};local secondItem={}
            state.owner=owner
            G.states[secondItem]={mode='off',owner=second}
            G.equipped=function(c) return c==owner and item or secondItem end
            local mount=G.mount;local fail=true
            G.mount=function(c,drawPose)
                if c==owner and fail then error('temporary draw transform failure') end
                return mount(c,drawPose)
            end
            draw(owner,{spriteBatch={},cam=cam})
            assert(G.drawError,'failed frame was not diagnosed')
            draw(second,{spriteBatch={},cam=cam})
            assert(#draws==5,'second wearer lost both arm and fan')
            fail=false;G.now=G.now+1
            render()
            local fan=false
            for _,d in ipairs(draws) do if d.path=='mod/Assets/AegisSuit/impeller.png' then fan=true end end
            assert(fan and #draws>=5,'first wearer did not resume drawing the arm and fan')
        """)

    def test_client_dispose_releases_all_loaded_sprites(self):
        self.lua.execute("""
            G.disposeClient()
            for _,s in ipairs(sprites) do assert(s.removed,'visual sprite leaked on reload') end
        """)
