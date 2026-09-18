return {
    radialMenu = {
        {
            label = 'Interaction',
            icon = 'hand',
            id = 'grim_interaction',
        },
    },
    radialSubMenu = {
        ['grim_interaction'] = {
            {
                label = 'Carry',
                icon = 'people-arrows',
                onSelect = function()
                    ExecuteCommand('carry')
                end
            },
            {
                label = 'Buhat',
                icon = 'people-carry',
                onSelect = function()
                    ExecuteCommand('buhat')
                end
            },
            {
                label = 'Piggyback',
                icon = 'person-walking',
                onSelect = function()
                    ExecuteCommand('piggyback')
                end
            },
        }
    }
}
