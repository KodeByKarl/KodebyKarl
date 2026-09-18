ConfigIpad = {}

ConfigIpad.OpenCommand = 'ipad'
ConfigIpad.OpenKey = 'F4'
ConfigIpad.UseProp = true
ConfigIpad.Prop = {
    model = `prop_cs_tablet`,
    bone = 28422,
    offset = vec3(0.0, 0.0, 0.0),
    rotation = vec3(0.0, 0.0, 0.0),
    dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a',
    anim = 'idle_a',
}

-- Economy app (owner / developer only)
ConfigIpad.EconomyGroups = {
    owner = true,
    developer = true,
}

-- Department Boss + MDT (live society + roster)
-- primaryJob = hired into this job; jobs = on-duty + off-duty for roster/MDT
ConfigIpad.Departments = {
    police = {
        label = 'Police Department',
        primaryJob = 'police',
        society = 'police',
        jobs = { 'police', 'offpolice' },
        bossMinGrade = 5,
        bossGradeNames = { boss = true, director = true, chief = true },
        mdt = true,
    },
    sheriff = {
        label = 'Sheriff Department',
        primaryJob = 'sheriff',
        society = 'sheriff',
        jobs = { 'sheriff', 'offsheriff' },
        bossMinGrade = 5,
        bossGradeNames = { boss = true, director = true, chief = true, sheriff = true },
        mdt = true,
    },
    ambulance = {
        label = 'EMS / Ambulance',
        primaryJob = 'ambulance',
        society = 'ambulance',
        jobs = { 'ambulance', 'offambulance' },
        bossMinGrade = 5,
        bossGradeNames = { boss = true, director = true, chief = true },
        mdt = false,
    },
    pambulance = {
        label = 'Paleto Ambulance',
        primaryJob = 'pambulance',
        society = 'pambulance',
        jobs = { 'pambulance', 'offpambulance' },
        bossMinGrade = 5,
        bossGradeNames = { boss = true, director = true, chief = true },
        mdt = false,
    },
    sambulance = {
        label = 'Sandy Ambulance',
        primaryJob = 'sambulance',
        society = 'sambulance',
        jobs = { 'sambulance', 'offsambulance' },
        bossMinGrade = 5,
        bossGradeNames = { boss = true, director = true, chief = true },
        mdt = false,
    },
    -- Boss/roster only. Police MDT shared via session + MDT access helpers (not police.jobs —
    -- that would incorrectly treat DOJ directors as PD bosses).
    doj = {
        label = 'Department of Justice',
        primaryJob = 'doj',
        society = 'doj',
        jobs = { 'doj', 'offdoj' },
        bossMinGrade = 5,
        bossGradeNames = { boss = true, director = true },
        mdt = false,
        sharePoliceMdt = true,
    },
}

-- Legacy aliases (kept for older references)
ConfigIpad.PoliceJobs = {
    police = true,
    offpolice = true,
    sheriff = true,
    offsheriff = true,
}
ConfigIpad.PoliceBossMinGrade = 5
ConfigIpad.BusinessBossMinGrade = nil -- nil = highest grade or grade_name boss

-- Organization app: gang bosses, plus owner / developer (full iPad visibility).

-- Business Boss and Organization apps removed
ConfigIpad.BusinessJobs = {}

ConfigIpad.Party = {
    MaxMembers = 4,
    MinNameLength = 3,
    MaxNameLength = 24,
    MaxPasswordLength = 16,
    EditPosCommand = 'movesquad', -- Drag the squad health/armor HUD
}

-- University Portal (iPad app) — job names that map into campus roles
ConfigIpad.UniversityJobs = {
    school = true,
    student = true,
    teacher = true,
}

-- grade_name (lowercase) → portal role
ConfigIpad.UniversityGradeRoles = {
    student = 'student',
    professor = 'teacher',
    teacher = 'teacher',
    faculty = 'teacher',
    dean = 'dean',
    director = 'director',
    boss = 'director',
}
