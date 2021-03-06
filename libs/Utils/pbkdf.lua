local ssl=require('openssl')
local x=require('./bits.lua')
local xor,bxor256=x[1],x[2]
local len,fmod,char,sub,ceil,concat,pack=string.len,math.fmod,string.char,string.sub,math.ceil,table.concat,string.pack
local function pbkdf(digest, password, salt, iteration, dkLen)
	local function PRF(P, S)
		local hmac = ssl.hmac.new(digest, P)
		return hmac:final(S, true)
	end

	local hLen = len(PRF('', ''))
	if dkLen > (2^32 - 1) * hLen then
		return nil, 'derived key too long'
	end

	local l = ceil(dkLen / hLen)

	local T = {}

	for i=1, l do
		local bytes = pack('!1>I4', fmod(i, 2 ^ (8 * 4)))
		local U = PRF(password, salt .. bytes)

		local t = {}

		for _=2, iteration do
			xor(t, U)
			U = PRF(password, U)
		end

		xor(t, U)
		T[i] = char(unpack(t))
	end

	return sub(concat(T), 1, dkLen)
end
return pbkdf