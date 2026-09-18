Config = Config or {}

Config.Invoice = {
    Enabled = true,
    Debug = false,

    OpenCommand = "billing",
    OpenKey = "", -- optional keybind, leave blank for command / export only

    NearbyDistance = 5.0,
    MaxTitleLength = 60,
    MaxDescriptionLength = 250,
    MaxAmount = 1000000,
    MinAmount = 1,

    -- Added on top of the entered price. 0 = no VAT/tax.
    VATPercent = 0,

    -- Optional screenshot overlay on invoice details (Copy / Cancel)
    ScreenshotEnabled = true,

    -- Jobs that can issue society (job) invoices. label = Invoice Type shown on the bill.
    -- forceSociety: always job invoice; paid funds go to that job's society account (never the officer).
    JobInvoices = {
        police = { label = "Law Enforcement", minGrade = 0, forceSociety = true },
        sheriff = { label = "Law Enforcement", minGrade = 0, forceSociety = true },
        ambulance = { label = "Emergency Medical", minGrade = 0 },
        sambulance = { label = "Emergency Medical", minGrade = 0 },
        pambulance = { label = "Emergency Medical", minGrade = 0 },
        doj = { label = "Department of Justice", minGrade = 0 },
        mechanic = { label = "Mechanic", minGrade = 0 },
        uwu = { label = "UwU Cafe", minGrade = 0 },
        burgershot = { label = "Burgershot", minGrade = 0 },
        taco = { label = "Taco Shop", minGrade = 0 },
        tacoshop = { label = "Tacoshop", minGrade = 0 },
        em = { label = "El Mofle", minGrade = 0 },
        mbotg = { label = "MBOTG", minGrade = 0 },
        ['8ball'] = { label = "8Ball", minGrade = 0 },
        weedshop = { label = "Weed Shop", minGrade = 0 },
    },

    -- Society Invoices + City Invoices: owner / developer only
    OwnerDevGroups = {
        owner = true,
        developer = true,
    },

    -- Inspect Citizen + leftover staff checks (owner / developer)
    StaffGroups = {
        owner = true,
        developer = true,
    },

    -- Inspect Citizen: these jobs (plus anyone in JobInvoices)
    InspectJobs = {
        police = true,
        sheriff = true,
        ambulance = true,
        sambulance = true,
        pambulance = true,
        doj = true,
        mechanic = true,
        uwu = true,
        burgershot = true,
        taco = true,
        tacoshop = true,
        em = true,
        mbotg = true,
        ['8ball'] = true,
        weedshop = true,
    },
}
