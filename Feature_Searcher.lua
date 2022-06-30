local ScriptName = "Feature Searcher"
local Version = "1.2"

local Parent = menu.add_feature(ScriptName, "parent")

local ParentFeatNames = {
	--Local
	"local.player_options",
	"local.vehicle_options",
	"local.model_changer",
	"local.outfits",
	"local.outfitter",
	"local.animations",
	"local.ptfx",
	"local.teleport",
	"local.aim_assist",
	"local.weapons",
	"local.weather_and_time",
	--"local.scripts",
	--"local.script_features",
	--"local.asi_plugins",
	"local.misc",
	"local.settings",
	
	--Online
	--"online.online_players",
	"online.all_players",
	"online.lobby",
	"online.services",
	"online.session_browser",
	"online.sc_browser",
	"online.join_timeout",
	"online.player_spoofer",
	"online.join_redirect",
	"online.net_sync_spoof",
	--"online.fake_friends",
	"online.radar",
	"online.esp",
	"online.modder_detection",
	"online.protections",
	"online.event_hooks",
	"online.tunables",
	"online.recovery",
	"online.casino_perico_heist",
	"online.business",
	"online.casino",
	"online.chat_commands",
	
	--Spawn
	"spawn.vehicles",
	"spawn.peds",
	"spawn.objects",
	"spawn.editor",
}

local notif = menu.notify
local function notify(msg, colour)
	notif(msg, ScriptName .. " v" .. Version, nil, colour)
	print(msg)
end

local AllFeats = {}

local function ProcessParent(featsTable, parent, namePrefix)
	namePrefix = namePrefix or ""
	namePrefix = namePrefix .. parent.name .. " > "
	
	print("<Feature Searcher v" .. Version .. "> Indexing " .. namePrefix)
	
	for i=1,parent.child_count do
		local child = parent.children[i]
		
		if child.type == 2048 then
			ProcessParent(featsTable, child, namePrefix)
		end
		
		featsTable[#featsTable + 1] = { Name = namePrefix .. child.name, SearchName = child.name:lower(), Feat = child }
		if #featsTable % 100 == 0 then
			system.wait(0)
		end
	end
end

menu.create_thread(function(featsTable)
	notify("Indexing features...", 0xFF00FFFF)
	local startTime = utils.time_ms()
	for i=1,#ParentFeatNames do
		local feat = menu.get_feature_by_hierarchy_key(ParentFeatNames[i])
		if not feat then
			print("<Feature Searcher v" .. Version .. "> Not indexing " .. ParentFeatNames[i])
		else
			ProcessParent(featsTable, feat)
		end
		system.wait(0)
	end
	local endTime = utils.time_ms()
	notify(string.format("Indexed %d features in %.3f seconds", #featsTable, (endTime - startTime) / 1000), 0xFF00FF00)
end, AllFeats)

local function Trim(s)
	local n = s:find"%S"
	return n and s:match(".*%S", n) or ""
end

local function DeleteFeature(Feat)
	if Feat.type == 2048 then
		for i=1,Feat.child_count do
			DeleteFeature(Feat.children[1])
		end
	end
	menu.delete_feature(Feat.id)
end

local function SelectFeat(f)
	if f.data.parent then
		f.data.parent:toggle()
	end
	f.data:select()
end

local function ToggleFeat(f)
	f.data:toggle()
end

local FilterFeat = menu.add_feature("Filter: <None>", "action", Parent.id, function(f)
	local r, s
	repeat
		r, s = input.get("Enter search query", f.data, 64, 0)
		if r == 2 then return HANDLER_POP end
		system.wait(0)
	until r == 0
	
	local threads = {}
	for i=f.parent.child_count,2,-1 do
		threads[#threads + 1] = menu.create_thread(DeleteFeature, f.parent.children[i])
	end
	
	local waiting = true
	while waiting do
		local running = false
		for i=1,#threads do
			running = running or (not menu.has_thread_finished(threads[i]))
		end
		waiting = running
		system.wait(0)
	end
	
	s = Trim(s)
	if s:len() == 0 then
		f.data = ""
		f.name = "Filter: <None>"
		return HANDLER_POP
	end
	
	local needle = s:lower()
	
	local count = 0
	for i=1,#AllFeats do
		local feat = AllFeats[i]
		if feat.SearchName:find(needle, w, true) then
			if feat.Feat.type == 2048 then
				menu.add_feature(feat.Name, "parent", Parent.id, ToggleFeat).data = feat.Feat
			else
				menu.add_feature(feat.Name, "action", Parent.id, SelectFeat).data = feat.Feat
			end
			count = count + 1
		end
	end
	
	f.data = s
	f.name = "Filter: <" .. s .. "> (" .. count .. ")"
end)
FilterFeat.data = ""

local ResetKey = MenuKey()
ResetKey:push_vk(0x11)
ResetKey:push_vk(0x24)
menu.create_thread(function(key)
	local pressed = false
	while true do
		if ResetKey:is_down() then
			if not pressed then
				Parent:toggle()
			end
			pressed = true
		else
			pressed = false
		end
		system.wait(0)
	end
end, ResetKey)