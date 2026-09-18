return {
    EnableJailCommand = true,                   -- Jail command using ox_lib input menu

    UnemployedJobName = 'unemployed',           -- Name of unemployed job (if remove job is enabled)

    AllowedToKeepItems = {                      --  Items found/received in prison that can be kept when released
        ['money'] = true
    },

    PoliceJobs = {                              -- Police jobs
        'police',
        'sheriff'
    },

    Lifers = {                                  -- Lifer identifiers
        'RANDOLIOCID',
        'QWADEBOTCID'
    },

    tempItems = {
        ['burger'] = 5,
        ['sprunk'] = 5,
        ['stresstabs'] = 5,
        -- ['robitussin'] = 5,
        -- ['ondansetron'] = 5,
        -- ['meclizine'] = 5
    },

    --[[
        Discord logs via kodebykarl-logs → POLICE channels:
        #JAIL #prison-releas #prison-break #prison-items
    ]]
    Logs = {
        Enabled = true,
        LogTypes = {
            jail = true,       -- jail + roster time change
            release = true,    -- unjail / roster unjail
            breakout = true,   -- escape, terminal hack, exploit ban
            items = true,      -- confiscate / return
        },
    },

    banPlayer = function(source, cid)
        if PrisonLogs and PrisonLogs.Exploit then
            PrisonLogs.Exploit({
                src = source,
                identifier = cid,
                reason = 'Tried to return prison items while still jailed / invalid terminal hack',
            })
        end
        DropPlayer(source, 'Trying to exploit? Gago!')
    end
}