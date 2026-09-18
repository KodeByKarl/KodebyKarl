-- Job announcements are registered on the server from jobTemplate.jobs.
-- Do not forward aliases to /wl — each job uses its own assigned command.

RegisterNetEvent('cfx-keydi-chat:openJobAutoTemplates', function()
    lib.notify({
        title = 'Announcement',
        description = 'Use your job command. Example: /pol or /ems [message].',
        type = 'inform',
    })
end)
