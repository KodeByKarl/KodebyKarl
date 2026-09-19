Config = {}

Config.Debug = false

-- Auto-create these society accounts on resource start (jobs / gangs).
-- Balance starts at 0 unless you set startingBalance.
Config.Accounts = {
    { name = 'society_police', label = 'Police Department', startingBalance = 0 },
    { name = 'society_sheriff', label = 'Sheriff Department', startingBalance = 0 },
    { name = 'society_ambulance', label = 'EMS / Ambulance', startingBalance = 0 },
    { name = 'society_pambulance', label = 'Paleto Ambulance', startingBalance = 0 },
    { name = 'society_sambulance', label = 'Sandy Ambulance', startingBalance = 0 },
    { name = 'society_doj', label = 'Department of Justice', startingBalance = 0 },
    { name = 'society_mechanic', label = 'Mechanic', startingBalance = 0 },
    { name = 'society_school', label = 'University of Los Santos', startingBalance = 0 },
    { name = 'society_uwu', label = 'UwU Cafe', startingBalance = 0 },
    { name = 'society_em', label = 'El Mofle', startingBalance = 0 },
    { name = 'society_taco', label = 'Taco Shop', startingBalance = 0 },
    { name = 'society_mbotg', label = 'MBOTG', startingBalance = 0 },
    { name = 'society_burgershot', label = 'Burger Shot', startingBalance = 0 },
    { name = 'society_8ball', label = '8Ball', startingBalance = 0 },
    { name = 'society_weedshop', label = 'Weed Shop', startingBalance = 0 },

    -- Gang societies (kodebykarl-gangsystem)
    { name = 'society_deuscartel', label = 'Deus Cartel', startingBalance = 0 },
    { name = 'society_grimgang', label = 'GrimGang', startingBalance = 0 },
    { name = 'society_alaskador', label = 'Alaskador', startingBalance = 0 },
    { name = 'society_westside', label = 'Westside', startingBalance = 0 },
    { name = 'society_mellysyndicate', label = 'Melly Syndicate', startingBalance = 0 },
    { name = 'society_npa', label = 'NPA', startingBalance = 0 },
    { name = 'society_tdc', label = 'Tropa de Calle', startingBalance = 0 },
    { name = 'society_tbs', label = 'The Boneless', startingBalance = 0 },
    { name = 'society_ghettosyndicate', label = 'Ghetto Syndicate', startingBalance = 0 },
    { name = 'society_ballas', label = 'Ballas', startingBalance = 0 },
    { name = 'society_families', label = 'Families', startingBalance = 0 },
    { name = 'society_vagos', label = 'Vagos', startingBalance = 0 },
    { name = 'society_lostmc', label = 'Lost MC', startingBalance = 0 },
    { name = 'society_marabunta', label = 'Marabunta', startingBalance = 0 },
}

-- Map job / gang id → society account name (helpers)
Config.JobAccounts = {
    police = 'society_police',
    offpolice = 'society_police',
    sheriff = 'society_sheriff',
    offsheriff = 'society_sheriff',
    ambulance = 'society_ambulance',
    offambulance = 'society_ambulance',
    pambulance = 'society_pambulance',
    offpambulance = 'society_pambulance',
    sambulance = 'society_sambulance',
    offsambulance = 'society_sambulance',
    doj = 'society_doj',
    offdoj = 'society_doj',
    mechanic = 'society_mechanic',
    offmechanic = 'society_mechanic',
    school = 'society_school',
    teacher = 'society_school',
    student = 'society_school',
    uwu = 'society_uwu',
    em = 'society_em',
    taco = 'society_taco',
    tacoshop = 'society_taco',
    mbotg = 'society_mbotg',
    burgershot = 'society_burgershot',
    ['8ball'] = 'society_8ball',
    weedshop = 'society_weedshop',
}

Config.GangAccounts = {
    deuscartel = 'society_deuscartel',
    grimgang = 'society_grimgang',
    alaskador = 'society_alaskador',
    westside = 'society_westside',
    mellysyndicate = 'society_mellysyndicate',
    npa = 'society_npa',
    tdc = 'society_tdc',
    tbs = 'society_tbs',
    ghettosyndicate = 'society_ghettosyndicate',
    ballas = 'society_ballas',
    families = 'society_families',
    vagos = 'society_vagos',
    lostmc = 'society_lostmc',
    marabunta = 'society_marabunta',
}

-- Write deposit/withdraw rows to cfx_society_ledger
Config.EnableLedger = true

-- Max ledger rows returned by GetLedger export
Config.LedgerLimit = 50

-- Optional: override boss grade per job (otherwise uses grade named "boss", else highest grade)
-- Config.BossGrades = {
--     mechanic = 3,
--     police = 4,
-- }
