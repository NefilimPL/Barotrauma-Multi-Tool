return {
    identifier='descendantservosuit', protocol='bmt.descendant.v2',
    -- Longer visible links stay folded inside the original operating radius.
    reach=92, upper=68, lower=60, repairBeam=50, combatRange=1800, grabRange=300,
    weldRate=48, grabDuration=5,
    shotInterval=.4,shotPower=.4,ammoCost=2.25,shotDamage=25,
    rates={repair=.4,weld=.6,combat=1,grab=.5,swim=.12}, rodMultiplier=.25,
    lifeSupportRate=.03,lightRate=.01,airOxygen=50, airPressure=20,
    scanInterval=.2, snapshotInterval=.1, servoDelay=.25, pressure=10000,
    maxGrabMass=80, grabForce=18, grabSpeed=4, swimForce=3, swimSpeed=5,
}
