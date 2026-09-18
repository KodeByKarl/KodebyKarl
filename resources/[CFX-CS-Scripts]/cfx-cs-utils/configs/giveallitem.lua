return {
    Enabled = true,
    NotifyTitle = 'GIVE ALL ITEM',
    -- Hard cap per player to prevent accidental mass dumps.
    MaxAmount = 50,
    -- ESX groups allowed to use /giveallitem (server-enforced, owner/dev only)
    AllowedGroups = {
        'owner',
        'developer',
    },
}
