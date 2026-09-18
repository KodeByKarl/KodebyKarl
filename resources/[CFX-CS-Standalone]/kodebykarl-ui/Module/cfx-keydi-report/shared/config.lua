ConfigReport = {}

ConfigReport.Debug = false
ConfigReport.OpenCommand = "report"
ConfigReport.ToggleKey = ""
ConfigReport.MaxDescriptionLength = 500
ConfigReport.MaxTitleLength = 80
ConfigReport.WebhookConvar = "modules_report_webhook"

ConfigReport.Categories = {
    { id = "bug", label = "Bug Reports" },
    { id = "rp", label = "RP Issues" },
    { id = "other", label = "Others" },
}

ConfigReport.StaffGroups = {
    developer = true,
    owner = true,
    admin = true,
    superadmin = true,
    mod = true,
}

-- Alert staff when a report is submitted / player replies
ConfigReport.StaffAlert = {
    enabled = true,
    -- PlaySoundFrontend name + set (loud / hard to miss)
    soundName = 'Event_Message_Purple',
    soundSet = 'GTAO_FM_Events_Soundset',
    -- Extra beeps so admins notice even if looking away
    repeats = 3,
    repeatDelayMs = 450,
    notifyDuration = 10000,
}
