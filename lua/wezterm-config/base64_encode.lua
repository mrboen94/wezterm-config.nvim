-- Use jit-cjson for high performance base64 encoding/decoding
local cjson = require("jit.cjson")
local ffi = require("ffi")
local bit = require("bit")

local base64 = {}

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local b64bytes = ffi.new("uint8_t[64]")
for i = 1, 64 do
    b64bytes[i-1] = b64chars:byte(i)
end

function base64.encode(str)
    local len = #str
    local outlen = math.ceil(len / 3) * 4
    local out = ffi.new("uint8_t[?]", outlen)
    local j = 0
    
    for i = 1, len-2, 3 do
        local a, b, c = str:byte(i, i+2)
        out[j] = b64bytes[bit.rshift(a, 2)]
        out[j+1] = b64bytes[bit.bor(bit.lshift(bit.band(a, 3), 4), bit.rshift(b, 4))]
        out[j+2] = b64bytes[bit.bor(bit.lshift(bit.band(b, 15), 2), bit.rshift(c, 6))]
        out[j+3] = b64bytes[bit.band(c, 63)]
        j = j + 4
    end

    local rest = len % 3
    if rest == 2 then
        local a, b = str:byte(-2, -1)
        out[j] = b64bytes[bit.rshift(a, 2)]
        out[j+1] = b64bytes[bit.bor(bit.lshift(bit.band(a, 3), 4), bit.rshift(b, 4))]
        out[j+2] = b64bytes[bit.lshift(bit.band(b, 15), 2)]
        out[j+3] = string.byte('=')
    elseif rest == 1 then
        local a = str:byte(-1)
        out[j] = b64bytes[bit.rshift(a, 2)]
        out[j+1] = b64bytes[bit.lshift(bit.band(a, 3), 4)]
        out[j+2] = string.byte('=')
        out[j+3] = string.byte('=')
    end

    return ffi.string(out, outlen)
end

function base64.decode(str)
    local len = #str
    if len % 4 ~= 0 then return nil, "invalid base64 length" end
    
    local padding = 0
    if str:sub(-2) == '==' then
        padding = 2
    elseif str:sub(-1) == '=' then
        padding = 1
    end
    
    local outlen = (len / 4) * 3 - padding
    local out = ffi.new("uint8_t[?]", outlen)
    local j = 0
    
    local lookup = {}
    for i = 1, 64 do
        lookup[b64chars:byte(i)] = i - 1
    end
    lookup[string.byte('=')] = 0
    
    for i = 1, len-3, 4 do
        local a = lookup[str:byte(i)]
        local b = lookup[str:byte(i+1)]
        local c = lookup[str:byte(i+2)]
        local d = lookup[str:byte(i+3)]
        
        out[j] = bit.bor(bit.lshift(a, 2), bit.rshift(b, 4))
        if j + 1 < outlen then
            out[j+1] = bit.bor(bit.lshift(bit.band(b, 15), 4), bit.rshift(c, 2))
        end
        if j + 2 < outlen then
            out[j+2] = bit.bor(bit.lshift(bit.band(c, 3), 6), d)
        end
        j = j + 3
    end
    
    return ffi.string(out, outlen)
end

return base64
