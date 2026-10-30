import unittest
from lua_support import LuaCase


class CombatCoreTests(LuaCase):

    def test_quality_sets_exact_bounce_budget(self):
        self.assertEqual([self.core.bounces(q) for q in [-10, 0, 1, 2, 3, 50]], [1, 1, 2, 3, 4, 4])

    def test_player_modes_are_exclusive(self):
        cases = [({}, 'weld'), ({'damage': True}, 'combat'),
                 ({'cutter': True}, 'cut'), ({'damage': True, 'cutter': True}, 'combat'),
                 ({'damage': True, 'extinguisher': True}, 'extinguish'),
                 ({'damage': True, 'repairing': True}, 'repair')]
        for props, expected in cases:
            self.assertEqual(self.core.mode(self.t(**props)), expected)

    def test_bot_uses_actual_task_not_checkboxes(self):
        for task, expected in [('weld', 'weld'), ('cut', 'cut'), ('repair', 'repair'),
                               ('extinguish', 'extinguish'), ('combat', 'combat'), ('queued', 'idle')]:
            self.assertEqual(self.core.mode(self.t(bot=True, task=task, damage=True, cutter=True, extinguisher=True)), expected)

    def test_bot_cannot_override_damage_permission(self):
        self.assertEqual(self.core.mode(self.t(bot=True, task='combat', damage=False)), 'idle')
        self.assertEqual(self.core.mode(self.t(bot=True, task='weld', damage=False)), 'weld')

    def test_reflection_uses_surface_normal(self):
        result = self.core.reflect(self.t(x=3, y=4), self.t(x=-1, y=0))
        self.assertAlmostEqual(result.x, -3)
        self.assertAlmostEqual(result.y, 4)

    def test_arc_only_intercepts_from_front(self):
        shield = self.t(x=0, y=0, radius=10, angle=0, halfAngle=1.05)
        hit = self.core.segmentArc(self.t(x=20, y=0), self.t(x=0, y=0), shield)
        self.assertAlmostEqual(hit[0], .5)
        self.assertIsNone(self.core.segmentArc(self.t(x=0, y=0), self.t(x=20, y=0), shield))
        self.assertIsNone(self.core.segmentArc(self.t(x=-20, y=0), self.t(x=0, y=0), shield))

    def test_arc_miss_and_tangent_do_not_intercept(self):
        shield = self.t(x=0, y=0, radius=10, angle=0, halfAngle=1.05)
        self.assertIsNone(self.core.segmentArc(self.t(x=20, y=20), self.t(x=0, y=20), shield))

    def test_energy_sources_are_independent_and_atomic(self):
        gun, shield = self.t(condition=2, multiplier=1), self.t(condition=40, multiplier=.25)
        self.assertTrue(self.core.spend(gun, 1))
        self.assertEqual(gun.condition, 1)
        self.assertEqual(shield.condition, 40)
        self.assertFalse(self.core.spend(gun, 6))
        self.assertEqual(gun.condition, 1)
        self.assertTrue(self.core.spend(shield, 4))
        self.assertEqual(shield.condition, 39)

    def test_empty_slot_cannot_borrow_other_slot(self):
        self.assertFalse(self.core.spend(None, 1))

    def test_shield_partial_energy_breaks_without_free_block(self):
        source = self.t(condition=1, multiplier=1)
        blocked, broken = self.core.shieldHit(source, 2)
        self.assertFalse(blocked)
        self.assertTrue(broken)
        self.assertEqual(source.condition, 0)

    def test_shield_exact_energy_blocks_then_breaks(self):
        source = self.t(condition=2, multiplier=1)
        blocked, broken = self.core.shieldHit(source, 2)
        self.assertTrue(blocked)
        self.assertTrue(broken)
        self.assertEqual(source.condition, 0)

    def test_contact_cost_exceeds_any_bullet_cost(self):
        self.assertGreater(self.core.config.shieldContactCost, self.core.config.shieldMaxHitCost)

    def test_ring_consumes_remaining_travel_after_bounce(self):
        self.lua.execute('''
            local Core = require('CombatTool.core')
            ring = Core.ring({x=0,y=0},{x=1,y=0},0)
            ring.speed = 100
            Core.advanceRing(ring, .2, function(a,b,r)
                if a.x < 10 and b.x >= 10 then return {t=(10-a.x)/(b.x-a.x), x=10,y=0,nx=-1,ny=0,kind='wall'} end
            end)
        ''')
        r = self.lua.globals().ring
        self.assertEqual(r.bouncesLeft, 0)
        self.assertAlmostEqual(r.x, 0, delta=.1)
        self.assertAlmostEqual(r.damageMultiplier, .85)

    def test_ring_next_wall_after_budget_kills_it(self):
        self.lua.execute('''
            local Core = require('CombatTool.core')
            ring = Core.ring({x=0,y=0},{x=1,y=0},0)
            ring.bouncesLeft = 0
            Core.advanceRing(ring, .2, function(a,b,r) return {t=.5,x=10,y=0,nx=-1,ny=0,kind='wall'} end)
        ''')
        self.assertFalse(self.lua.globals().ring.alive)

    def test_ring_lifetime_and_distance_are_bounded(self):
        self.lua.execute('''
            local Core = require('CombatTool.core')
            ring = Core.ring({x=0,y=0},{x=1,y=0},3)
            Core.advanceRing(ring, 100, function() end)
        ''')
        r = self.lua.globals().ring
        self.assertFalse(r.alive)
        self.assertLessEqual(r.distance, 3200)


if __name__ == '__main__':
    unittest.main()
