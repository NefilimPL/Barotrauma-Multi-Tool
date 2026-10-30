-- All costs are percentage points of the installed source's condition.
return {
    identifier = 'combatmultitool', protocol = 'bmt.combat.v1',
    chargeTime = 0.25, reloadTime = 0.65, shotCost = 1, toolCost = 0.2,
    lightCost = 0.025, rodMultiplier = 0.25,
    speed = 1400, lifetime = 2.5, maxDistance = 3200,
    radius = 6, maxRadius = 12, bounceRetention = 0.85, maxStepContacts = 8,
    burnDamage = 18, bluntDamage = 12,
    shieldRadius = 95, shieldHalfAngle = math.pi / 3,
    shieldIdleCost = 0.1, shieldMinHitCost = 1, shieldMaxHitCost = 4,
    shieldContactCost = 6, shieldContactInterval = 0.75,
    shieldCooldown = 3, contactBurn = 1, contactStun = 0.25,
    snapshotInterval = 0.1, resupplyInterval = 1, resupplyTimeout = 12,
    maxRings = 128,
}
