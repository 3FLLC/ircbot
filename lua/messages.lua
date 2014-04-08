--Functions for handling incoming messages

--Our function that's called whenever we get a message on IRC
local function gotmessage(user, command, where, target, message)
	--print("[from: " .. user .. "] [reply-with: " .. command .. "] [where: " .. where .. "] [reply-to: " .. target .. "] ".. message)
	
	message = message:gsub("\r", "")	--Strip off \r\n
	message = message:gsub("\n", "")
	
	if message:sub(1, 1) == '!' then	--Bot action preceded by '!' character
		local botaction = string.sub(message, 2)	--Get bot action
		doaction(target, botaction, user)
	end
	
	--Update last seen message
	lastseen[string.lower(user)] = os.clock()
	message = message:gsub("\001[Aa][Cc][Tt][Ii][Oo][Nn]", user) --Replace \001ACTION with username
	message = message:gsub("\001", "")	--Remove trailing \001
	lastmessage[string.lower(user)] = "saying \""..message.."\""
	
	--Test for links
	for w in string.gmatch(message, "https?://%S+") do
		local title = getURLTitle(w)
		say(target, "["..title.."]")
    end
	
	--TODO: Test for bad words, bird words, RPS battle commands, yelling
	
end
setglobal("gotmessage", gotmessage)

local function rejoin(channel)
	sleep(60*2)
	join(channel)
end

local function joined(channel, user)
	lastseen[string.lower(user)] = os.clock()
	lastmessage[string.lower(user)] = "joining IRC"
	nicks[string.lower(user)] = 1;
end

local function left(channel, user)
	lastseen[string.lower(user)] = os.clock()
	lastmessage[string.lower(user)] = "leaving IRC"
	nicks[string.lower(user)] = nil
end

local function kicked(channel, user)
	say(channel, "Trololol")
	lastseen[string.lower(user)] = os.clock()
	lastmessage[string.lower(user)] = "being kicked from IRC"
	nicks[string.lower(user)] = nil
end

local function nicklist(channel, user, buf)
	buf = string.gsub(buf, ":.+:", "")
	for n in string.gmatch(buf, "%S+") do 
		nicks[string.lower(n)] = 1
	end
end

local function changenick(channel, user, buf)
	buf = string.gsub(buf, ":.+:", "")	--Remove all but message
	nicks[string.lower(user)] = nil
	nicks[string.lower(buf)] = 1
	lastseen[string.lower(user)] = os.clock()
	lastseen[string.lower(buf)] = os.clock()
	lastmessage[string.lower(user)] = "changing nick to "..buf 
	lastmessage[string.lower(buf)] = "changing nick from "..user
end

local function command(channel, cmd, user, buf)
	local actions = {
		["001"] = join,
		["JOIN"] = joined,
		["PART"] = left,
		["QUIT"] = left,
		["KICK"] = kicked,
		["353"] = nicklist,
		["404"] = rejoin,
		["NICK"] = changenick,
	}
	
	local f = actions[cmd]
	if f then
		f(channel, user, buf)
	end
end
setglobal("command", command)