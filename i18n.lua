i18 = {
	["ru"] = {
		["level"] = "УРОВЕНЬ";
		["completed"] = "ПРОЙДЕН",
		["tries"] = "ПОПЫТОК",
		["score"] = "СЧЁТ",
		["demo"] = "ДЕМО",
	}
}

_ = function(s)
	local l = LANG
	local a = s:gsub("^([^:]+):.*$", "%1")
	s = s:gsub("^[^:]+:", "")
	if not l or not i18[l] then
		return s
	end
	local ss = i18[l][a] 
	if ss then return ss end
	return s
end
