--[[
    ULS Registrar + enrollment applications
    Keydi.dev · Grim City
]]

ConfigUniversity = {}

ConfigUniversity.Enabled = true
ConfigUniversity.Label = 'ULS Registrar'
ConfigUniversity.Brand = 'Keydi.dev'

-- Job granted when Director/Dean approves an application
ConfigUniversity.StudentJob = 'school'
ConfigUniversity.StudentGrade = 0

-- Optional ox_inventory item on approve
ConfigUniversity.StudentIdItem = 'student_id'
ConfigUniversity.GiveStudentId = true

-- Who can approve / deny in the iPad portal
ConfigUniversity.ApproverRoles = {
    dean = true,
    director = true,
}

ConfigUniversity.Programs = {
    { id = 'aes',  code = 'AES',  label = 'Aesthetic Services (Beauty Care)' },
    { id = 'aut',  code = 'AUT',  label = 'Automotive' },
    { id = 'cjps', code = 'CJPS', label = 'Criminal Justice and Public Safety' },
    { id = 'fab',  code = 'FAB',  label = 'Food and Beverage' },
    { id = 'hcs',  code = 'HCS',  label = 'Health Care Services' },
    { id = 'bsit', code = 'BSIT', label = 'Information Technology' },
}

ConfigUniversity.Registrar = {
    enabled = true,
    model = `a_f_y_business_02`,
    coords = vec4(-1650.85, 186.42, 61.75, 115.0), -- adjust to your MLO desk
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    targetDistance = 2.4,
    targetIcon = 'fa-solid fa-graduation-cap',
    targetLabel = 'Talk to Registrar',
}

ConfigUniversity.Notify = {
    applied = 'Application submitted. Wait for Director / Dean approval.',
    cancelled = 'Application cancelled.',
    alreadyPending = 'You already have a pending application.',
    alreadyStudent = 'You are already enrolled at ULS.',
    approved = 'Welcome to ULS — your enrollment was approved.',
    denied = 'Your ULS application was denied.',
}
