return {
    Enabled = true,
    Zones = {
        {
            name = 'weedfarm_redzone',
            label = 'WeedFarm Redzone Area',
            enterMessage = 'You are inside the WeedFarm Redzone Area',
            exitMessage = 'You left the WeedFarm Redzone Area',
            textUI = 'You are inside the **WeedFarm Redzone Area**',
            textUIPosition = 'bottom-center',
            textUIIcon = 'fa-solid fa-triangle-exclamation',
            debug = false,
            thickness = 80.0,
            points = {
                vec3(2161.4204, 5552.6611, 53.1463),
                vec3(2262.7261, 5542.6602, 50.9980),
                vec3(2239.3062, 5639.0229, 57.7313),
                vec3(2195.5981, 5636.8081, 58.8888),
            },
        },
        {
            name = 'methfarm_redzone',
            label = 'MethFarm Redzone Area',
            enterMessage = 'You are inside the MethFarm Redzone Area',
            exitMessage = 'You left the MethFarm Redzone Area',
            textUI = 'You are inside the **MethFarm Redzone Area**',
            textUIPosition = 'bottom-center',
            textUIIcon = 'fa-solid fa-triangle-exclamation',
            debug = false,
            thickness = 80.0,
            points = {
                vec3(2404.3018, 4958.0557, 44.3540),
                vec3(2440.3037, 4928.0020, 44.9889),
                vec3(2488.9380, 4978.6328, 45.0245),
                vec3(2459.7654, 5013.9941, 45.5655),
            },
        },
    },
}
