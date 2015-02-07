global { menu_mode = 'title' }

level_reset = function(win, notitle)
	key_empty()
	if win and not demo_mode then
		history_store(win)
	end
	happy_end_off = 0
	sprite.copy(sprite.screen(), offscreen)
	menu_select('level_out', 0)
	level_load()
	local st = level_stat()
	local bant
	history = {}
	if demo_mode then
		bant = sprite.text(fn2, stead.string.format(_("demo:DEMO").." %d", nr_level + 1), 'red', 1)
	elseif notitle then
		bant = false
	else
		if win then
			bant = sprite.text(fn2, stead.string.format(_("score:SCORE").." %d", nr_score), 'red', 1)
		else
			bant = sprite.text(fn2, stead.string.format(_("try:TRIES").." %d", st.die), 'red', 1)
		end
	end
	demo_mode = false
	nr_score = 0;
	sprite.fill(banner, 'black')
	if bant then
		local w, h = sprite.size(bant)
		sprite.draw(bant, banner, (scr_w - w) / 2, 0)
		sprite.free(bant)
	end
	timer:set(FAST_TIMER)
	if level_after then
		level_after()
		level_after = false
	end
end

level_movein = function()
	local st = level_stat()
	local bant
	if not demo_mode then
		if nr_level == nr_levels then
			bant = sprite.text(fn2, stead.string.format(_("end:THE END")), 'red', 1)
		else
			bant = sprite.text(fn2, stead.string.format(_("level:LEVEL").." %d", nr_level + 1), 'red', 1)
		end
	else
		bant = sprite.text(fn2, stead.string.format(_("demo:DEMO").." %d", nr_level + 1), 'red', 1)
	end
	local w, h = sprite.size(bant)
	sprite.fill(banner, 'black')
	sprite.draw(bant, banner, (scr_w - w) / 2, 0)
	sprite.free(bant)

	sound.play(sounds[SLEVELIN], 3)
	timer:set(FAST_TIMER)
	menu_select('level_in', scr_h + h)
end

level_ready = function()
	menu_select(false)
	level_render(sprite.screen());
	timer:set(TIMER)
end

level_choose = function()
	if nr_level >= nr_levels then
		nr_level = 0
	end
	menu_select('level_select', true)
	level_load()

	select_time = 0

	sprite.fill(offscreen, 'black')
	level_map(offscreen, (scr_w - 256) / 2, (scr_h - 256) / 2)

	local st = level_stat()
	local lev = sprite.text(fn, stead.string.format(_("level:LEVEL").." %d", nr_level + 1), 'red', 1)
	local w, h = sprite.size(lev)

	sprite.fill(offscreen, (scr_w - 256) / 2, (scr_h - 256) / 2 - h - h / 2, 256, h, 'black');
	sprite.draw(lev, offscreen, (scr_w - 256) / 2 + (256 - w) / 2, (scr_h - 256) / 2 - h - h / 2);
	sprite.free(lev)
	sprite.fill(offscreen, (scr_w - 256) / 2, (scr_h - 256) / 2 + 256 + h /2, 256, h, 'black');

	if st.completed > 0 then
		lev = sprite.text(fn, stead.string.format(_("completed:COMPLETED"), st.completed), 'red', 1)
		local w, h = sprite.size(lev)
		sprite.draw(lev, offscreen, (scr_w - 256) / 2, (scr_h - 256) / 2 + 256 + h / 2);
		sprite.free(lev)

		lev = sprite.text(fn, stead.string.format(_("score:SCORE").." %d", st.score), 'red', 1)
		local w, h = sprite.size(lev)
		sprite.draw(lev, offscreen, (scr_w - 256) / 2 + (256 - w), (scr_h - 256) / 2 + 256 + h / 2);
		sprite.free(lev)
	elseif st.die > 0 then
		lev = sprite.text(fn, stead.string.format(_("try:TRIES").." %d", st.die), 'red', 1)
		local w, h = sprite.size(lev)
		sprite.draw(lev, offscreen, (scr_w - 256) / 2 + (256 - w) / 2, (scr_h - 256) / 2 + 256 + h / 2);
		sprite.free(lev)
	end

	sprite.copy(offscreen, sprite.screen())
	if (nr_level + 1) ~= nr_levels then
		sprite.copy(ra_spr, sprite.screen(), scr_w - 24 - 16, 256 - 16)
	end

	if nr_level > 0 then
		sprite.copy(la_spr, sprite.screen(), 24, 256 - 16)
	end

	timer:set(FAST_TIMER / 2)
end

MAP_SPEED = 32

demo_enter = function()
	local l
	local ll = {}
	menu_select('demo', true)
	for l = 0, nr_levels -1 do
		if history_check(l) then
			stead.table.insert(ll, l)
		end
	end
	if #ll == 0 then return end
	nr_level = ll[rnd(#ll)]
	level_load()
	level_reset(false, true)
	level_after = title_enter
	history_load()
	demo_mode = true
end

function menu_select(name, var)
	menu_mode = name
	if name then
		_G[name..'_mode'] = var
	end
end

function menu_title_mode()
	title_time = title_time + 1
	if title_time > 300 then
		title_time = 0
		demo_enter()
		return true
	end
	if title_mode ~= true then
		title_mode = title_mode - 32
		if title_mode < 32 then title_mode = 32 end
		title_render(sprite.screen(), 0, title_mode);
	end
	if title_mode == 32 then
		title_mode = true
		local s
		if total_score and total_score > 0 then
			s = sprite.text(tfn, stead.string.format(_("score:SCORE").." %d", total_score), '#00ff00', 1)
			local w, h = sprite.size(s)
			sprite.draw(s, sprite.screen(), scr_w - w - 2, 2);
			sprite.free(s)
		end

		local s = sprite.text(tfn, stead.string.format(_("version:Version").." 1.2"), '#0000ff', 1)
		local w, h = sprite.size(s)

		sprite.draw(s, sprite.screen(), 2, 2);
		sprite.free(s)
	end 
	if title_mode == true and is_anykey() then
		key_empty()
		bank_choose()
		sound.play(sounds[SPHASER], 3)
		return true
	end
	local w,h = sprite.size(press_any_key)
	if title_mode == true then
		sprite.fill(sprite.screen(), 
			(scr_w - w) / 2, scr_h - h * 2, w, h, 'black');
		if stead.math.floor(title_time / 10) % 2 ~= 0 then
			sprite.draw(press_any_key, sprite.screen(), 
				(scr_w - w) / 2, scr_h - h * 2);
		end
	end
	return true
end

function menu_level_in_mode()
	local bw,bh = sprite.size(banner)
	if level_in_mode < 0 then level_in_mode = 0 end
	sprite.copy(banner, sprite.screen(), 0, level_in_mode - bh)
	level_render(sprite.screen(), level_in_mode)
	if level_in_mode == 0 then
		level_ready()
		return true
	end
	level_in_mode = level_in_mode - 8
	return true
end

function menu_level_out_mode()
	local bw,bh = sprite.size(banner)
	if level_out_mode >= scr_h + bh then level_out_mode = scr_h + bh end
	sprite.fill(sprite.screen(), 0, level_out_mode - 8 - bh, scr_h, level_out_mode, 'black')
	sprite.copy(banner, sprite.screen(), 0, level_out_mode - bh);
	sprite.copy(offscreen, sprite.screen(), 0, level_out_mode)
	if level_out_mode == scr_h + bh then
		level_movein()
		return true
	end
	level_out_mode = level_out_mode + 8
	return true
end

function bank_choose()
	select_time = 0
	sprite.fill(sprite.screen(), 'black')
	sprite.copy(sprite.screen(), offscreen);
	local sw, sh = banks[nr_bank].sw, banks[nr_bank].sh
	sprite.draw(banks[nr_bank].spr, offscreen, (scr_w - sw) / 2, (scr_h - sh)/ 2);
	sprite.copy(offscreen, sprite.screen());
	if nr_bank < #banks then
		sprite.copy(ra_spr, sprite.screen(), scr_w - 24 - 16, 256 - 16)
	end
	if nr_bank > 1 then
		sprite.copy(la_spr, sprite.screen(), 24, 256 - 16)
	end
	sw, sh = sprite.size(select_maps_spr)
	sprite.draw(select_maps_spr, sprite.screen(), (scr_w - sw)/2, 32)
	menu_select('bank_select', true)
end

function menu_bank_select_mode()
	if bank_select_mode ~= true then
		local sw, sh = banks[nr_bank].sw, banks[nr_bank].sh

		local h = (scr_h - sh) / 2

		if bank_select_mode < 0 then
			sprite.fill(sprite.screen(), scr_w + bank_select_mode, h, sw, sh, 'black')
			bank_select_mode = bank_select_mode - MAP_SPEED
			sprite.copy(offscreen, sprite.screen(), bank_select_mode, 0)
			if bank_select_mode < -scr_w + (scr_w - sw )/ 2 then
				bank_select_mode = -scr_w + (scr_w - sw )/ 2
			end
			sprite.draw(banks[nr_bank].spr, sprite.screen(), scr_w + bank_select_mode, h);
		else
			sprite.fill(sprite.screen(), bank_select_mode - sw, h, sw, sh, 'black')
			bank_select_mode = bank_select_mode + MAP_SPEED
			sprite.copy(offscreen, sprite.screen(), bank_select_mode, 0)
			if bank_select_mode > (scr_w + sw )/ 2 then
				bank_select_mode = (scr_w + sw )/ 2
			end
			sprite.draw(banks[nr_bank].spr, sprite.screen(), bank_select_mode - sw, h);
		end

		if bank_select_mode <= -scr_w + (scr_w - sw )/ 2 or bank_select_mode >= (scr_w + sw )/ 2 then
			bank_choose();
		end

	end
	if bank_select_mode == true then
		if (is_key 'down' or is_key 'right') and nr_bank < #banks then
			_G["_selected_level_"..banks[nr_bank].name] = selected_level -- old selection
			nr_bank = nr_bank + 1
			bank_select_mode = -MAP_SPEED
		elseif (is_key 'up' or is_key 'left') and nr_bank > 1 then
			_G["_selected_level_"..banks[nr_bank].name] = selected_level -- old selection
			nr_bank = nr_bank - 1
			bank_select_mode = MAP_SPEED
		elseif is_return() then
			bank_load()
			key_empty()
			level_choose()
			return true
		end
		if not select_time then select_time = 0 end
		select_time = select_time + 1
		if select_time >= 1000 then select_time = 0 end
		local w,h = sprite.size(press_enter)
		sprite.fill(sprite.screen(), (scr_w - w) / 2, scr_h - h * 2, w, h, 'black');
		if stead.math.floor(select_time / 10) % 2 ~= 0 then
			sprite.draw(press_enter, sprite.screen(), (scr_w - w) / 2, scr_h - h * 2);
		end
	end
	return true
end

function menu_level_select_mode()
	local level_select = level_select_mode
	if level_select ~= true then -- scroll
		sprite.copy(offscreen, sprite.screen(), level_select, 0)
		if level_select < 0 then
			sprite.fill(sprite.screen(), level_select + scr_w, 0, MAP_SPEED, scr_h, 'black')
			level_map(sprite.screen(), scr_w + level_select, (scr_h - 256) / 2)
			sprite.fill(sprite.screen(), scr_w + level_select + 256, 0, MAP_SPEED, scr_h, 'black')
			level_select = level_select - MAP_SPEED
		else
			sprite.fill(sprite.screen(), level_select, 0, MAP_SPEED, scr_h, 'black')
			level_map(sprite.screen(), level_select - 256, (scr_h - 256) / 2)
			sprite.fill(sprite.screen(), level_select - 256 - MAP_SPEED, 0, MAP_SPEED, scr_h, 'black')
			level_select = level_select + MAP_SPEED
		end
		if level_select < -384 or level_select > 400 then
			level_choose()
			level_select = true
		end
		level_select_mode = level_select
	end

	if level_select == true then
		select_time = select_time + 1
		if select_time >= 1000 then select_time = 0 end
		local w,h = sprite.size(press_enter)
		sprite.fill(sprite.screen(), (scr_w - w) / 2, scr_h - h * 2, w, h, 'black');
			if stead.math.floor(select_time / 10) % 2 ~= 0 then
			sprite.draw(press_enter, sprite.screen(), 
				(scr_w - w) / 2, scr_h - h * 2);
		end
		if is_key 'down' and nr_level < nr_levels - 1 then
			nr_level = nr_level + 10
			if nr_level >= nr_levels then
				nr_level = nr_levels - 1
			end
			selected_level = nr_level
			level_select_mode = -MAP_SPEED
			level_load()
		elseif is_key 'right' and nr_level < nr_levels - 1 then
			nr_level = nr_level + 1
			selected_level = nr_level
			level_select_mode = -MAP_SPEED
			level_load()
		elseif is_key 'up' and nr_level > 0 then
			nr_level = nr_level - 10
			if nr_level < 0 then
				nr_level = 0
			end
			selected_level = nr_level
			level_select_mode = MAP_SPEED
			level_load()
		elseif is_key 'left' and nr_level > 0 then
			nr_level = nr_level - 1
			selected_level = nr_level
			level_select_mode = MAP_SPEED
			level_load()
		elseif is_return() then
			selected_level = nr_level
			_G["_selected_level_"..banks[nr_bank].name] = selected_level -- old selection
			sprite.fill(sprite.screen(), 'black')
			stop_music();
			level_load()
			level_movein()
			return true
		elseif is_demo() and history_check(nr_level) then
			sprite.fill(sprite.screen(), 'black')
			level_load()
			history_load()
			level_movein()
			level_after = level_choose
			demo_mode = true
			return true
		end
	end
	return true
end

function menu_demo_mode()
end

title = {
"     :   : ::: :  : ::: ::      ",
"     :: ::  :  :: : :   : :     ",
"     : : :  :  : :: ::  ::      ",
"     :   :  :  :  : :   : :     ",
"     :   : ::: :  : ::: : :     ",
"                                ",
"     ####   ###  ##   ####      ",
"     ## ## ## ## ##   ## ##     ",
"     ####  ## ## ##   ## ##     ",
"     ## ## ## ## ##   ## ##     ",
"     ####   ###  #### ####      ",
};
title_text = {
"                                    ИНСТРУКЦИЯ:",
"    Ваша задача: собрать все алмазы в лабиринте и перейти",
"в следующий.",
"    Попадаться в руки бабочкам и минам, а также оказаться",
"под падающим камнем или алмазом опасно для жизни.",
"    Ваших сил хватит для толкания камней в любом",
"направлении. Остальное поймете сами по ходу игры.",
" ",
"    Программа была написана А. В. Меленьтевым в 1989 г.",
"для БК-0010. Оформлять игру помог Н. Валтер.",
"    Порт игры под INSTEAD выполнен П. А. Косых в 2015 г.",
}

title_text_en = {
"                                    INSTRUCTIONS:",
" ",
"    Your mission: got all jewels on the level. Avoid butterfiles",
" mines and falling stones.",
"    You are strong enougth to move stones in any direction.",
"    Good luck!",
" ",
"    Original code was written by A. V. Melentiev in 1989.",
"for BK-0010 computers. N. Walter helped him.",
"    Ported to INSTEAD by P.A. Kosyh in 2015.",
}
happy_end_map = 

{
"::::::::::::::::",
"               $",
"                ",
"                ",
"                ",
"+      @@       ",
"::::::::::::::::",
"%              &",
"                ",
"                ",
"                ",
"                ",
"                ",
"                ",
"                ",
"                ",
}

happy_end_text = {
"Поздравляю!",
"Вы прошли эту непростую игру!",
" ",
"Надеюсь, она понравилась вам также",
"как и мне 25 лет назад...",
" ",
"Кстати, вы можете смотреть записанные",
"демонстрации, нажав на клавишу D",
"из режима выбора уровня",
"или прямо во время игры",
" ",
"Вы можете посмотреть",
"другие INSTEAD игры по адресу:",
"http://instead.syscall.ru",
" ",
"Выражаю благодарность и признательность:",
" ",
"Жене и детям",
"за понимание",
" ",
"А. В. Мелентьеву и Н. Валтеру",
"за Bolder Dash для БК-0010",
" ",
"Леониду Брухису",
"За эмулятор БК-0010 для Unix",
" ",
"Всем разработчикам БК-0010",
" ",
"Без всех этих людей",
"ремейк игры был бы невозможен...",
" ",
" ",
"В игре использованы треки:",
" ",
"Chip never dies от ajaxlemon",
"IBM 486 66Mhz от ExcelioN",
" ",
" ",
" ",
" ",
"КОНЕЦ",
" ",
" ",
" ",
" ",
"                   Косых Петр 2015",
}

happy_end_text_en = {
"Congratulations!",
"You win!",
" ",
"I hope you like this small game",
"It was written 25 years ago...",
" ",
"Btw, you may run demo of any level",
"Just press D key from map selection",
"menu or just in game",
" ",
"Visit http://instead.syscall.ru",
"for other INSTEAD games",
" ",
"Thanks to:",
" ",
"My wife and childrens",
" ",
"A. V. Melentiev and N. Walter",
"for they Bolder Dash game",
" ",
"Leonid A. Broukhis",
"for БК-0010 emulator",
" ",
"And all BK-0010 developers!",
" ",
"Thank you for playing this game!",
" ",
" ",
"Music:",
" ",
"Chip never dies by ajaxlemon",
"IBM 486 66Mhz by ExcelioN",
" ",
" ",
" ",
" ",
"THE END",
" ",
" ",
" ",
" ",
"                   Peter Kosyh 2015",
}
happy_end_spr = {}
happy_end_render = function()
	if not happy_end_off then
		happy_end_off = 0
	end
	local off = happy_end_off
	local het = happy_end_text
	if LANG ~= 'ru' then
		het = happy_end_text_en
	end
	local k,v 
	local fh = sprite.font_height(tfn)
	local off2 = off
	local bh = scr_h / 2
	local delta = bh - off
	local start = 1
	local start_y = scr_h
	if not happy_end_spr_w then
		happy_end_spr_w = 0
		happy_end_spr_h = 0
		for k,v in ipairs(het) do
			local w,h = sprite.text_size(tfn, v)
			if w > happy_end_spr_w then
				happy_end_spr_w = w
			end
			happy_end_spr_h = happy_end_spr_h + h
		end
	end
	if delta < 0 then
		for k,v in ipairs(het) do
			if delta + fh >= 0 then
				start = k
				start_y = delta
				break
			end
			if happy_end_spr[k] then
				sprite.free(happy_end_spr[k])
				happy_end_spr[k] = nil
			end
			delta = delta + fh
		end
	else
		start_y = delta
	end
--prite.fill(sprite.screen(), (scr_w - happy_end_spr_w)/2, scr_h /2, happy_end_spr_w, scr_h / 2, "black")
	local ox = (scr_w - happy_end_spr_w)/2
	for k = start, #het do
		v = het[k]
		if not happy_end_spr[k] then
			happy_end_spr[k] = sprite.text(tfn, v, '#ff0000', 1)
		end
	local w, h = sprite.size(happy_end_spr[k])
		if delta < 0 and k == start then
			sprite.draw(happy_end_spr[k], 0, -delta, w, h + delta, sprite.screen(), ox + (happy_end_spr_w - w)/2, scr_h /2 + start_y - delta)
		else
			sprite.draw(happy_end_spr[k], sprite.screen(), ox + (happy_end_spr_w - w)/2, scr_h/2 + start_y)
		end
		start_y = start_y + fh
		if start_y >= scr_h then
			break
		end
	end
	happy_end_off = happy_end_off + 2
	if happy_end_off > (happy_end_spr_h + bh)  then
		happy_end_off = 0
	end
end

title_render = function(where, ox, oy)
	local char2map = {
		[' '] = 0,
		[':'] = 1,
		['@'] = 2,
		['$'] = 3,
		['+'] = 4,
		['#'] = 5,
		['&'] = 6,
		['%'] = 7,
	}
	local x
	local y
	for y = 1, #title do
		for x = 1, 32 do
			local c = string.sub(title[y], x, x);
			c = char2map[c]
			sprite.copy(sprites_small[c + 1], where, 
				ox + (x - 1) * 16, oy + (y - 1) * 16);
		end
	end
	sprite.fill(where, 0, oy + #title * 16, 512, 32, 'black');
	sprite.fill(where, 0, oy - 32, 512, 32, 'black');
	local k,v
	if not title_tspr then
		tspr_width = 0
		title_tspr = {}
		local t = title_text_en
		if LANG == "ru" then
			t = title_text
		end
		for k,v in ipairs(t) do
			title_tspr[k] = sprite.text(tfn, v, '#00ff00', 1)
			local w, h = sprite.size(title_tspr[k])
			if w > tspr_width then tspr_width = w end
		end
	end
	local dh = #title * 16 + 16
	local fh = sprite.font_height(tfn)
	fh = fh + stead.math.floor(fh / 3)
	for k, v in ipairs(title_tspr) do
		sprite.fill(where, ox, oy + dh + (k - 1) * fh, scr_w, h, 'black')
	end
	local dy
	for k, v in ipairs(title_tspr) do
		local w, h = sprite.size(v)
		dy = oy + dh + (k - 1) * fh
		sprite.draw(v, where, ox + (scr_w - tspr_width) / 2, dy)
	end
	sprite.fill(where, 0, dy + fh, scr_w, 32, 'black')
end

title_enter = function()
	set_music('snd/chipneve.xm')
	menu_select('title', scr_h)
	demo_mode = false
	title_time = 0
	timer:set(FAST_TIMER)
--	sound.stop(-1)
	sound.play(sounds[STRILL], 3)
	level_after = false
	key_empty()
	local k,v

	local score = 0

	for k,v in pairs(prefs.stat) do
		if v.score then
			score = score + v.score
		end
	end
	total_score = score
end
