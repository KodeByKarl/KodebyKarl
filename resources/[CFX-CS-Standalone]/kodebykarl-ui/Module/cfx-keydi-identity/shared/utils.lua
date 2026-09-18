IdentityUtils = IdentityUtils or {}

function IdentityUtils.Debug(msg, ...)
    if Config.Debug then
        print(("^5[cfx-keydi-ui - DEBUG] %s^7"):format(tostring(msg):format(...)))
    end
end
