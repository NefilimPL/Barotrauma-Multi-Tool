return {
    identifier='descendantservosuit', protocol='bmt.descendant.v4',
    -- Longer visible links stay folded inside the original operating radius.
    reach=118, upper=76, lower=66, repairBeam=68, toolOffset=24, toolStandOff=14,
    contactSlack=32,contactGrace=.4,combatRange=1800,grabRange=300,
    weldRate=64, grabDuration=5,
    shotInterval=.4,shotPower=.4,ammoCost=2.25,shotDamage=20,
    jointEase=.12,jointSpeed=4,headSpeed=7,replicaEase=.055,toolAngleTolerance=.07,
    gripOcclusionGrace=3,gripReleaseRange=380,gripProbeInterval=.12,
    rates={repair=.4,weld=.6,combat=1,grab=.5,swim=.12}, rodMultiplier=.25,
    lifeSupportRate=.03,lightRate=.01,airOxygen=50, airPressure=20,
    scanInterval=.2, snapshotInterval=.1, servoDelay=.1, pressure=10000,
    maxGrabMass=80,grabForce=18,grabSpeed=8,grabSpring=60,grabDamping=15,grabAcceleration=80,
    grabHoldDistance=120,sonarRate=.12,pulseDuration=.14,controlBurst=4,controlRate=10,swimForce=3,swimSpeed=5,
}
