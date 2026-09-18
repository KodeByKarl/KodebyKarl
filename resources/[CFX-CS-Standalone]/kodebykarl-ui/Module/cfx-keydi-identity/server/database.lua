Database = {}

function Database.GetIdentity(identifier, cb)
    MySQL.single('SELECT firstname, lastname, dateofbirth, sex, height FROM users WHERE identifier = ?', { identifier }, function(result)
        if result then
            cb({
                firstName = result.firstname,
                lastName = result.lastname,
                dateOfBirth = result.dateofbirth,
                sex = result.sex,
                height = result.height
            })
        else
            cb(nil)
        end
    end)
end

function Database.SaveIdentity(identifier, identity, cb)
    MySQL.update('UPDATE users SET firstname = ?, lastname = ?, dateofbirth = ?, sex = ?, height = ? WHERE identifier = ?', {
        identity.firstName,
        identity.lastName,
        identity.dateOfBirth,
        identity.sex,
        identity.height,
        identifier
    }, function(rowsChanged)
        if cb then
            cb(rowsChanged ~= nil)
        end
    end)
end

function Database.DeleteIdentity(identifier, cb)
    MySQL.update('UPDATE users SET firstname = ?, lastname = ?, dateofbirth = ?, sex = ?, height = ? WHERE identifier = ?', {
        nil, nil, nil, nil, nil, identifier
    }, function(rowsChanged)
        if cb then
            cb(rowsChanged > 0)
        end
    end)
end
