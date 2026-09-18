return {
    menu = {
        KeyMapping = 'U',
        KeyMappingLabel = 'Open Clothing Menu',
        Command = 'clothes_menu'
    },
    -- Male undress (from pedmenu): jacket 15, shirt 15, hands 219, legs 61, shoes 253
    male = {
        Torso = 15,
        Torso2 = 0,
        Pants = 61,
        Pants2 = 0,
        Shoes = 253,
        Shoes2 = 0,
        Bag = 0,
        Bag2 = 0,
        Gloves = 219,
        Gloves2 = 0,
        Hat = -1,
        Glasses = -1,
        Mask = 0,
        Mask2 = 0,
        Shirt = 15,
        Shirt2 = 0,
        Ears = -1,
        Vest = 0,
        Vest2 = 0,
        Chain = 0,
        Chain2 = 0
    },
    -- Female undress (from pedmenu): jacket 15, shirt 15, hands 262, legs 15, shoes 277
    female = {
        Torso = 15,
        Torso2 = 0,
        Pants = 15,
        Pants2 = 0,
        Shoes = 277,
        Shoes2 = 0,
        Bag = 0,
        Bag2 = 0,
        Gloves = 262,
        Gloves2 = 0,
        Hat = -1,
        Glasses = -1,
        Mask = 0,
        Mask2 = 0,
        Shirt = 15,
        Shirt2 = 0,
        Ears = -1,
        Vest = 0,
        Vest2 = 0,
        Chain = 0,
        Chain2 = 0
    },
    commands = {
        { Command = 'shirt', type = 'shirt' },
        { Command = 'hat', type = 'helmet' },
        { Command = 'mask', type = 'mask' },
        { Command = 'ears', type = 'ears' },
        { Command = 'pants', type = 'pants' },
        { Command = 'shoes', type = 'shoes' },
        { Command = 'bag', type = 'bag' },
        { Command = 'chain', type = 'chain' },
        { Command = 'glasses', type = 'glasses' },
        { Command = 'vest', type = 'vest' }
    }
}
