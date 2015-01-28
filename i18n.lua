i18 = {
	["ru"] = {
		["version"] = "Версия";
		["warning"] = "Пожалуйста, разрешите в настройках собственные темы игр.";
		["level"] = "УРОВЕНЬ";
		["completed"] = "ПРОЙДЕН",
		["try"] = "ПОПЫТОК",
		["score"] = "СЧЁТ",
		["demo"] = "ДЕМО",
		["press"] = "НАЖМИТЕ ЛЮБУЮ КЛАВИШУ",
		["press_enter"] = "НАЖМИТЕ ВВОД",
		["end"] = "КОНЕЦ",
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
