--$Name:Miner Bold$
--$Version:1.3$
--$Author:Peter Kosyh$

instead_version "2.0.0"
TIMER = 85
FAST_TIMER = 30

require "sprites"
require "sound"
require "timer"
require "kbd"
require "click"

-- require "prefs"

sprites = {}
sprites_small = {}

history = {}

sounds = {}
global {
	nr_level = 0;
	selected_level = 0;
	nr_score = 0;
	map = {};
	prefs = { }
};

prefs.stat = {}
prefs.maps_stat = {}

SDIE = 1
SFALL = 2
SCLICK = 3
SLEVELIN = 4
STRILL = 5
SPHASER = 6

load_sounds = function()
	sounds[SDIE] = sound.load "snd/explode.ogg"
	sounds[SFALL] = sound.load "snd/fall.ogg"
	sounds[SCLICK] = sound.load "snd/click.ogg"
	sounds[SLEVELIN] = sound.load "snd/levelin.ogg"
	sounds[STRILL] = sound.load "snd/trill.ogg"
	sounds[SPHASER] = sound.load "snd/phaser.ogg"
end

load_sprites = function()
	local i
	local files = { 
		'00.png',
		'01.png',
		'02.png',
		'03.png',
		'04.png',
		'05.png',
		'06.png',
		'07.png',
		'02.png',
		'02.png',
		'03.png',
		'03.png',
		'12.png',
		'13.png',
		'14.png',
		'15.png',
		'16.png',
		'17.png',
		'18.png',
		'19.png',
		'20.png',
		'21.png',
	}
	for i=1, #files do 
		local s = sprite.load("gfx/"..files[i])
		if i <= 8 then
			sprites_small[i] = s
		end
		sprites[i] = sprite.scale(s, 2.0, 2.0, false)
--		sprite.free(s)
	end
	fn = sprite.font("gfx/font.ttf", 16);
	fn2 = sprite.font("gfx/font.ttf", 26);
	tfn = sprite.font("gfx/font.ttf", 12);
	press_any_key = sprite.text(tfn, _("press:PRESS ANY KEY"), 'red', 1)
	press_enter = sprite.text(fn, _("press_enter:PRESS ENTER"), 'red', 1)
	select_maps_spr = sprite.text(fn2, _("banks:SELECT GAME"), 'red', 1)
	la_spr = sprite.load("gfx/la.png")
	ra_spr = sprite.load("gfx/ra.png")
end

BEMPTY = 0
BGRASS = 1
BSTONE = 2
BSTONE_LAZY = BSTONE + 128
BGOLD = 3
BHUMAN = 4
BBLOCK = 5
BHEART = 6
BFLY = 7

BSTONE2 = BSTONE * 2 + 4
BSTONE3 = BSTONE2 + 1

BGOLD2 = BGOLD * 2 + 4
BGOLD3 = BGOLD2 + 1

global {
	scatter_dir = -1;
	enemies = {};
}

level_store = function()
	local map2char = {
		[0] = ' ',
		[1] = ':',
		[2] = '@',
		[3] = '$',
		[4] = '+',
		[5] = '#',
		[6] = '&',
		[7] = '%',
	}
	local x
	local y
	for y = 0, 15 do
		local line = ''
		for x = 0, 15 do
			local c = cell_get(x * 2, y * 2)
			c = map2char[c];
			line = line .. c;
		end
		maps[nr_level * 16 + y + 1] = line
	end
end

level_load = function()
	enemies = {};
	history = {}
	scatter_dir = -1

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
	local line = nr_level * 16
	local x
	local y
	local was_human
	for y = 1, 16 do
		map[y] = {}
		local row = maps[line + y]
		for x = 1, 16 do
			local c = string.sub(row, x, x);
			c = char2map[c]
			if c == BHUMAN and was_human then
				c = BEMPTY
			end
			map[y][x] = c
			if c == BHUMAN then
				was_human = true
				player_x = (x - 1) * 2
				player_y = (y - 1) * 2
				player_movex = 0;
				player_movey = 0;
			elseif c >= BHEART then --
				stead.table.insert(enemies, { x = (x - 1) * 2, y = (y - 1) * 2, dx = 0, dy = 0 })
			end
		end
	end
	if not was_human then
		player_x = 0
		player_y = 0
		player_movex = 0;
		player_movey = 0;
		map[1][1] = BHUMAN
	end
end

scr_w = 512
scr_h = 512

level_render = function(where, offset)
	if not offset then offset = 0 end
	local y
	local x
	for y = 1,16 do
		local yy = 32 * (y - 1) + offset
		if yy >= scr_h then
			return
		end
		if yy >= 0 then
			local l = map[y]
			for x = 1, 16 do
				local c = l[x] + 1
				sprite.copy(sprites[c], where, 32 * (x - 1), yy)
			end
		end
	end
end
level_map = function(where, ox, oy)
	local y
	local x
	for y = 1,16 do
		local yy = 16 * (y - 1)
		local l = map[y]
		for x = 1, 16 do
			local c = l[x] + 1
			sprite.copy(sprites_small[c], where, 16 * (x - 1) + ox, yy + oy)
		end
	end
end

keys = {}
key_empty = function()
	fingers = {}
	keys = {}
	key_any, key_esc, key_demo, key_return, key_edit = false, false, false, false, false
end

fingers = {}
touch_stamp = 0;
touch_num = 0
touch_max = 0
if stead.finger_pos then
	require "finger"
	game.finger = function(s, press, fid, x, y)
		use_fingers = true
		if press then
			if stead.ticks() - touch_stamp > 200 then
				touch_num = 0
				touch_stamp = stead.ticks()
			end
			touch_num = touch_num + 1
			touch_max = #finger:list()
		else
			local tm = touch_max
			touch_num = 0
			touch_stamp = 0
			touch_max = 0
			if tm >=4 and edit_mode then
				local x, y
				for y=0, 15 do
					for x=0, 15 do
						sprite_draw(x * 2, y * 2, BEMPTY);
						cell_set(x * 2, y * 2, BEMPTY);
					end
				end
				return
			elseif tm >= 3 then
				key_edit = true
				return
			end
		end
		if touch_num >= 3 then
			key_esc = true
			return
		end
		if press and x > scr_w / 3 and x < scr_w * 2 / 3 and not edit_mode and touch_max == 1 then
			key_return = press
			key_any = press
		end
		if press then
			stead.table.insert(fingers, 1, { id = fid, x = x, y = y })
		else
			local k,v
			for k,v in ipairs(fingers) do
				if v.id == fid then
					stead.table.remove(fingers, k)
					break
				end
			end
			if #fingers == 0 then
				key_empty()
			end
		end
	end
end

function check_fingers()
	if not use_fingers then
		return
	end
	keys = {}

	local fng = finger:list()
	local k, v
	if #fingers == 0 then
		return
	end
	local V
	for k,v in ipairs(fng) do
		if v.id == fingers[1].id then
			V = v
			break
		end
	end
	if not V then
		stead.table.remove(fingers, 1) -- lost one?
		return
	end
	v = V

	local dx = v.x - fingers[1].x
	local dy = v.y - fingers[1].y

	local r = stead.math.sqrt(dx*dx + dy*dy)

	if r < 8 then
		return
	end

	if stead.math.abs(dx) >= stead.math.abs(dy) then
		-- lr
		if dx < 0 then
			game:kbd(true, 'left')
		else
			game:kbd(true, 'right')
		end
	else
		-- ud
		if dy < 0 then
			game:kbd(true, 'up')
		else
			game:kbd(true, 'down')
		end
	end
end

click_history = { {0,0}, {0,0}, {0,0}, {0,0} }
cell_edit = function(x, y, a)
	local c = cell_get(x, y)
	if c == edit_c and not a then
		edit_c = c + 1
	else
		edit_c = edit_c or c
	end
	if edit_c > 7 then 
		edit_c = 0
	end
	cell_set(x, y, edit_c)
end

game.click = function(s, x, y, a, b)
	if edit_mode and not menu_mode then
		local nx = math.floor(x / 32) * 2;
		local ny = math.floor(y / 32) * 2;
		if nx == player_x and ny == player_y then
			cell_edit(player_x, player_y)
		else
			sprite_draw(player_x, player_y, cell_get(player_x, player_y));
			player_x, player_y = nx, ny
--			cell_edit(player_x, player_y);
		end
	end
end

game.kbd = function(s, down, key)
	if key == 'space' or key == 'return' then
		key_return = down
		return
	end

	if key == 'escape' or key == 'backspace' then
		if menu_mode ~= 'title' then
			key_esc = down
			return true
		end
		key_esc = false
	end

	if key == 'd' then
		key_demo = down
		return
	end

	if key == 'e' then
		key_edit = down
		return
	end

	if key >= '0' and key <= '7' then
		key_num = down and key
		return
	end

	if not down then
		local k,v
		local i
		for k,v in ipairs(keys) do
			if v == key then
				i = k
				break
			end
		end
		if i then
			stead.table.remove(keys, i)
		end
		return
	end
	s:kbd(false, key) -- release first
	stead.table.insert(keys, 1, key)
end


banks = {
}

banks_init = function(s)
	local k,v
	local m = {}
	for v in stead.readdir(instead_gamepath()) do
		if v:find("%.map$") then
			stead.table.insert(m, v)
		end
	end
	stead.table.sort(m, function(a ,b) 
				if a == 'maps.map' then 
					return true 
				elseif b == 'maps.map' then
					return false
				else 
					return a < b 
				end 
	end)
	for k, v in ipairs(m) do
		local f = io.open(instead_gamepath().."/"..v)
		if f then
			local l
			local name = v:gsub("%.map$", "")
			local sname = name
			local name_i18n = false
			for l in f:lines() do
				if not l:find("^%-%-") and not l:find("^[ \t]*$") then
					break
				end
				if l:find("$Name:", 1, true) then
					name = l:gsub("^.*%$Name:[ \t]*(.*)[ \t]*$", "%1")
				elseif l:find("%$Name%([a-zA-Z]+%):") then
					name_i18n = l:gsub("^.*%$Name%(([a-zA-Z]+)%):[ \t]*(.*)[ \t]*$", "%2")
					name_lang = l:gsub("^.*%$Name%(([a-zA-Z]+)%):[ \t]*(.*)[ \t]*$", "%1")
				end
			end
			if name_i18n then
				stead.table.insert(banks, { title = name, title_i18n = { [name_lang] = name_i18n }, file = v, name = sname })
			else
				stead.table.insert(banks, { title = name, file = v, name = sname })
			end
			f:close();
		end
	end
	for k,v in ipairs(banks) do
		local title = v.title
		if v.title_i18n and v.title_i18n[LANG] then
			title = v.title_i18n[LANG]
		end
		v.spr = sprite.text(fn2, title, '#ff0000', 1)
		v.sw, v.sh = sprite.size(v.spr)
	end
	nr_bank = 1
end

game.timer = function(s)
	local rc
	check_fingers()
	if menu_mode then
		rc = _G['menu_'..menu_mode..'_mode']()
	end
	if is_esc() then
		title_enter()
		return
	end
	if not rc then
		game_loop()
	end
end

pos2cell = function(x, y)
	return stead.math.floor(x / 2), stead.math.floor(y / 2)
end

cell2pos = function(x, y)
	return x * 2, y * 2
end

sprite_draw = function(x, y, c)
	sprite.copy(sprites[c + 1], sprite.screen(), 16 * x, 16 * y)
end

cell_set = function(x, y, c)
	x, y = pos2cell(x, y)
	if x < 0 or x > 15 or y < 0 or y > 15 then
		return
	end
	map[y + 1][x + 1] = c
end

cell_get = function(x, y, c)
	x, y = pos2cell(x, y)
	return map[y + 1][x + 1]
end

global {
	player_x = 0;
	player_y = 0;
	player_movex = 0;
	player_movey = 0;
}

is_key = function(n)
	if keys[1] == n then
		return true
	end
end

is_return = function()
	return key_return
end

is_esc = function()
	return key_esc
end

is_anykey = function()
	local c = key_any
	key_any = false
	if c then
		key_return = false
		key_esc = false
	end
	return c
end

input.key = stead.hook(input.key, function(f, s, down, key, ...)
	if not key:find("escape") and not key:find("shift")
		and not key:find("ctrl")
		and not key:find("alt")
		and not key:find("unknown") then
		key_any = down
	end
	return f(s, down, key, ...)
end)

is_demo = function()
	if key_demo then
		return true
	end
end

is_edit = function()
	if key_edit then
		key_edit = false
		return true
	end
end

human_stone = function(x, y)
	local xx, yy, c 
	xx, yy = x + player_movex * 2, y + player_movey * 2
	while true do
		if xx >= 32 or yy >= 32 or xx < 0 or yy < 0 then
			return human_stop(x, y)
		end
		c = cell_get(xx, yy)
		if c == BEMPTY then
			break
		end
		if c ~= BSTONE and c ~= BSTONE3 then
			return human_stop(x, y)
		end
		xx, yy = xx + player_movex * 2, yy + player_movey * 2
	end
	cell_set(xx, yy, BSTONE_LAZY)
	cell_set(x, y, BEMPTY);
	sprite_draw(x, y, BEMPTY);
	sprite_draw(xx, yy, BSTONE);
	return human_move(x, y)
--	local c = cell_get(xx, yy)
--	if c == BEM
end
human_stop = function(x, y)
	sprite_draw(player_x, player_y, BHUMAN)
end
human_gold = function(x, y)
	-- sound
	sound.play(sounds[SCLICK])
	-- score
	nr_score = nr_score + 1
	return human_move(x, y)
end

human_move = function(x, y)
	sprite_draw(player_x, player_y, BEMPTY)
	if player_movex ~= 0 or player_movey ~= 0 then
		if player_movex < 0 then
			c = 16
		elseif player_movex > 0 then
			c = 18
		elseif player_movey < 0 then
			c = 12
		else
			c = 14
		end
		sprite_draw(player_x + player_movex, player_y + player_movey, c)
		cell_set(x, y, c)
		x, y = player_x + player_movex, player_y + player_movey
	else
		cell_set(player_x, player_y, BEMPTY)
		cell_set(x, y, BHUMAN)
	end
	player_x, player_y = x, y
end

human_death = function(x, y)
	explode(x, y)
	level_stat().die = level_stat().die + 1
	stead.autosave()
	level_reset()
end

game_dispatch = function(c, x, y)
	local dt = {
		[BEMPTY] = human_move, -- 0
		[BGRASS] = human_move, -- 1
		[BSTONE] = human_stone, -- 2
		[BGOLD] = human_gold, --3
		[BBLOCK] = human_stop, --5
		[BHEART] = human_death, --6
		[BFLY] = human_death, --7
		[BSTONE2] = human_stop, -- 8
		[BSTONE3] = human_stone, -- stone
		[BGOLD2] = human_stop, -- 8
		[BGOLD3] = human_gold, -- gold
		[20] = human_death,
		[21] = human_death,
	}
	local fn = dt[c]
	if not fn then
		error("Unknown dispatcher: "..c)
	end
	return fn(x, y)
end

check_scatter = function(cc, x, y, d)
	if d == 1 and x == 30 then
		return false
	end
	if d == -1 and x == 0 then
		return false
	end
	local c = cell_get(x + d * 2, y + 2)
	if c ~= BEMPTY then
		return false
	end
	c = cell_get(x + d * 2, y)
	if c ~= BEMPTY then
		return false
	end
	cell_set(x + d * 2, y, cc)
	cell_set(x, y, BEMPTY)
	sprite_draw(x, y, BEMPTY)
	sprite_draw(x + d * 2, y, cc)
	return true
end
fall1 = function(x, y, c)
	local sc = true
	if y < 30 then
		local cd = cell_get(x, y + 2)
		if cd == BEMPTY then
			c = c * 2 + 4
			cell_set(x, y + 2, c)
			cell_set(x, y, c)
			sprite_draw(x, y, BEMPTY);
			sprite_draw(x, y + 1, c)
			return x, y
		else -- scatter
			local dir = scatter_dir
			
			scatter_dir = - scatter_dir
			if not check_scatter(c, x, y, dir) then
				dir = - dir
				sc = check_scatter(c, x, y, dir)
			end
			if dir == 1 and sc then
				return x + 2, y
			end
		end
	end
	if not sc then
		cell_set(x, y, c)
	end
	return x, y
end
explode = function(x, y)
	x = x + 2
	local xe = x
	y = y + 2
	local ye = y
	local xs = x - 4
	if xs < 0 then
		xs = xs + 2
	end
	local ys = y - 4
	if ys < 0 then
		ys = ys + 2
	end
	if xe > 31 then
		xe = xe - 1
	end
	if ye > 31 then
		ye = ye - 1
	end
	for y = ys, ye, 2 do
		for x = xs, xe, 2 do
			cell_set(x, y, BGOLD)
			sprite_draw(x, y, BGOLD)
		end
	end
	-- sound
	sound.play(sounds[SDIE])
--	local c = cell_get(player_x, player_y)
--	if c ~= BHUMAN and c < 12 then
--		level_stat().die = level_stat().die + 1
--		prefs:store()
--		stead.autosave()
--		level_reset()
--	end
	return xe, ye
end
bank_stat = function()
	local st = prefs.stat
	local nam = banks[nr_bank].name
	if nam ~= 'maps' then
		if not prefs.maps_stat then
			prefs.maps_stat = {}
		end
		st = prefs.maps_stat[nam]
		if not st then
			prefs.maps_stat[nam] = {}
		end
		st = prefs.maps_stat[nam]
	end
	return st
end

level_stat = function()
	local st = bank_stat()
	local lst = st[nr_level]
	if not lst then
		st[nr_level] = { }
	end
	st = st[nr_level]
	if type(st.completed) ~= 'number' then
		st.completed = 0
	end
	if type(st.die) ~= 'number' then
		st.die = 0
	end
	if type(st.score) ~= 'number' then
		st.score = 0
	end
	return st
end

fall = function()
	local nr_gold = 0
	local x, y, c
	for y = 30,0,-2 do
		x = 0
		while x <= 30 do 
			if level_out then
				return
			end
			c = cell_get(x, y)
			if c == BGOLD or c == BGOLD3 or c == BGOLD2 then
				nr_gold = nr_gold + 1
			end
			if c == BSTONE_LAZY then
				c = BSTONE
				cell_set(x, y, c)
			elseif c == BGOLD or c == BSTONE then
				x, y = fall1(x, y, c)
			elseif c == BSTONE2 or c == BGOLD2 then
				cell_set(x, y - 2, BEMPTY) 
				sprite_draw(x, y - 2, BEMPTY);
				cell_set(x, y, c + 1)
				sprite_draw(x, y, c + 1)
			elseif c == BGOLD3 or c == BSTONE3 then
				if y == 30 then
					c = (c - 5) / 2
					cell_set(x, y, c);
					-- sound
					sound.play(sounds[SFALL])
					sprite_draw(x, y, c);
				else
					local cd = cell_get(x, y + 2)
					if cd == BHUMAN or cd == BHEART or cd == BFLY or cd >= 12 then
						-- explode
						-- print("explode")
						x = explode(x, y + 2);
					else
						if cd ~= BEMPTY then
							-- sound
							sound.play(sounds[SFALL])
						end
						c = (c - 5)  /2
						x, y = fall1(x, y, c)
					end
				end
			end
			x = x + 2
		end
	end
-- 	check if dead
	c = cell_get(player_x, player_y)
	if c ~= BHUMAN and c < 12 then
--		print ("dec lives"..c)
		level_stat().die = level_stat().die + 1
--		prefs:store()
		stead.autosave()
		level_reset()
		return
	end
	if nr_gold == 0 then -- or is_return() then -- hack
		-- completed
		if demo_mode then
			level_reset()
			return
		end
		if nr_level == nr_levels then
			title_enter()
			return
		end
		level_stat().completed = level_stat().completed + 1
		if level_stat().score < nr_score then
			level_stat().score = nr_score
		end
--		prefs:store()
		stead.autosave()
		local l = nr_level
		nr_level = nr_level + 1
		if nr_level == nr_levels then
			-- lookup first undone
			local i
			for i=0,nr_levels - 1 do
				if (not bank_stat()[i] or 
				    not bank_stat()[i].completed or 
				    bank_stat()[i].completed == 0) then
					nr_level = i
					break
				end
			end
		end
		if nr_level == nr_levels then
			-- todo game over
			nr_level = nr_levels
			level_reset(l)
			set_music 'snd/486.xm'
		else
			selected_level = nr_level
			level_reset(l)
		end
	end
end

enemy_halflife = function(c)
	if c < 16 then
		c = c + 14
	else
		c = c - 14
	end
	return c
end

enemy_turn = function(x, y, c, w, e)
	sprite_draw(x, y, BEMPTY)
	c = enemy_halflife(c)
	local dx, dy = w.dx, w.dy
	e.x, e.y, e.dx, e.dy = x + dx, y + dy, dx, dy
	sprite_draw(e.x, e.y, c)
	cell_set(e.x + dx, e.y + dy, c)
	return
end

enemy_logic = function(i)
	local ways = {}
	local x, y, dx, dy
	local e = enemies[i]
	x, y, dx, dy = e.x, e.y, e.dx, e.dy
	local c = enemy_cell(i)
	if (x % 2 ~= 0) or (y % 2) ~= 0 then -- odd
		c = enemy_halflife(c)
		cell_set(x - dx, y - dy, BEMPTY)
		sprite_draw(x - dx, y - dy, BEMPTY)
		x, y = x + dx, y + dy
		cell_set(x, y, c)
		sprite_draw(x, y, c)
		e.x, e.y = x, y
		return
	end
	 -- even, logic decision
	local delta = -1
	local half = true
--	print "start"
	while true do
		local xm, ym
		if half then
			ym = y + delta * 2
			xm = x
		else
			xm = x + delta * 2
			ym = y
		end
		if xm >= 0 and ym >= 0 and xm < 32 and ym < 32 then
			local cc = cell_get(xm, ym)
			if (cc == BEMPTY or cc == BHUMAN) then
			-- can walk
				if half then
					stead.table.insert(ways, { dx = 0, dy = delta })
				else
					stead.table.insert(ways, { dx = delta, dy = 0 })
				end
			end
		end
		if half then
			half = false
			-- continue
		else -- flip
			delta = - delta
			if delta > 0 then -- another half
				half = true
				-- continue
			else -- all scan is done
				break
			end
		end
	end
--	print "break"
	if #ways == 0 then
		c = enemy_halflife(c)
		cell_set(x, y, c)
		sprite_draw(x, y, c)
		return
	end
	if #ways > 1 then
	-- do not walk backwards!
		local i,k
		for k,v in ipairs(ways) do
			if v.dx == -e.dx and v.dy == - e.dy then
				stead.table.remove(ways, k)
				break
			end
		end
	end

	if #ways == 1 then -- only 1 path
		enemy_turn(x, y, c, ways[1], e)
		return
	end
	-- chose best one!
	dx = player_x - x
	dy = player_y - y
	if dx < 0 then
		dx = -1
	else
		dx = 1
	end
	if dy < 0 then
		dy = -1
	else
		dy = 1
	end
	local best = 0
	local best_w = ways[1]
	for k,v in ipairs(ways) do
		local new_best = dx + v.dx
		local a = new_best
		if new_best < 0 then new_best = - new_best end
		local d = dy + v.dy
		if d < 0 then d = - d end
		new_best = new_best + d
		if new_best > best then
			best = new_best
			best_w  = v
		end
	end
	enemy_turn(x, y, c, best_w, e)
end

enemy_cell = function(i)
	local e = enemies[i]
	local x, y, dx, dy = e.x, e.y, e.dx, e.dy
	if (x % 2) ~= 0 then
		x = x - dx
	end
	if (y % 2) ~= 0 then
		y = y - dy
	end
	return cell_get(x, y)
end

enemy = function()
	if #enemies == 0 then
		return
	end
	local x, y, dx, dy, c, i, e
	i = 1
	while true do
		if i > #enemies then
			break
		end
		e = enemies[i]
		x, y, dx, dy = e.x, e.y, e.dx, e.dy
		c = enemy_cell(i)
		if c ~= BFLY and c ~= BHEART and c ~= 20 and c ~= 21 then
			if (x % 2 ~= 0) or (y % 2) ~= 0 then
				x = x + dx
				y = y + dy
				cell_set(x, y, BEMPTY)
				sprite_draw(x, y, BEMPTY)
			end
			-- remove enemy
			stead.table.remove(enemies, i)
		else
			enemy_logic(i)
			i = i + 1
		end
		
	end
	c = cell_get(player_x, player_y)
	if c == BHUMAN then
		return
	end
	if c < 12 or c >= 20 then
		return human_death(player_x, player_y)
	end
end

history_name = function(nr)
	local n = banks[nr_bank].name
	if n == 'maps' then
		return "demo"
	end
	return "demo-"..n.."-"
end

history_check = function(nr)
	local p = instead_gamepath().."/"..history_name()..tostring(nr + 1)
	local f = io.open(p, "r")
	if not f then
		p = instead_savepath().."/"..history_name()..tostring(nr + 1)
		f = io.open(p, "r")
	end
	if not f then
		return false
	end
	f:close()
	return true
end

history_load = function()
	local p = instead_gamepath().."/"..history_name()..tostring(nr_level + 1)
	local f = io.open(p, "r")
	if not f then
		p = instead_savepath().."/"..history_name()..tostring(nr_level + 1)
		f = io.open(p, "r")
	end
	if not f then
		history = {}
		return
	end
	local l
	history = {}
	for l in f:lines() do
		local v = {}
		for a in l:gmatch("[0-9-]+") do
			stead.table.insert(v, tonumber(a))
		end
		stead.table.insert(history, v)
	end
	f:close(p)
end

history_store = function(n)
	local p = instead_savepath().."/"..history_name()..tostring(n + 1)
	local f = io.open(p, "w")
	local k,v
	for k,v in ipairs(history) do
		f:write(stead.string.format("%d %d %d\n", v[1], v[2], v[3]))
	end
	f:close(p)
end

history_get = function()
	if #history == 0 then
		level_load()
		level_reset()
		return 0, 0
--		return 0, 0
	end
	local v = stead.table.remove(history, 1)
	v[3] = v[3] - 1
	if v[3] > 0 then
		stead.table.insert(history, 1, v)
	end
	return v[1], v[2]
end

history_add = function(dx, dy)
	if #history == 0 then
		stead.table.insert(history, {dx, dy, 1})
		return
	end
	local n = #history
	local v = history[n]
	if v[1] == dx and v[2] == dy then
		v[3] = v[3] + 1
		return
	end
	stead.table.insert(history, {dx, dy, 1})
	return
end

game_loop = function()
	if is_demo() and not demo_mode and history_check(nr_level) then
		level_load()
		level_reset()
		history_load()
		demo_mode = true
		return
	end

	if demo_mode and is_anykey() then
		level_load()
		level_reset()
		return
	end
	if is_edit() then
		local new_mode = not edit_mode
		if edit_mode then
			level_store()
			bank_save()
		end
		level_load()
		level_reset()
		edit_mode = new_mode
		return
	end
	if edit_mode then
		edit_blink = not edit_blink
		local active_edit = false
		if is_key 'up' then
			active_edit = touch_max >= 1
			if acive_edit then cell_edit(player_x, player_y, active_edit); end
			sprite_draw(player_x, player_y, cell_get(player_x, player_y));
			player_y = player_y - 2
			edit_blink = false
		elseif is_key 'down' then
			active_edit = touch_max >= 1
			if acive_edit then cell_edit(player_x, player_y, active_edit); end
			sprite_draw(player_x, player_y, cell_get(player_x, player_y));
			player_y = player_y + 2
			edit_blink = false
		elseif is_key 'left' then
			active_edit = touch_max >= 1
			if acive_edit then cell_edit(player_x, player_y, active_edit); end
			sprite_draw(player_x, player_y, cell_get(player_x, player_y));
			player_x = player_x - 2
			edit_blink = false
		elseif is_key 'right' then
			active_edit = touch_max >= 1
			if acive_edit then cell_edit(player_x, player_y, active_edit); end
			sprite_draw(player_x, player_y, cell_get(player_x, player_y));
			player_x = player_x + 2
			edit_blink = false
		end
		if player_x < 0 then player_x = 0 end
		if player_x > 30 then player_x = 30 end
		if player_y < 0 then player_y = 0 end
		if player_y > 30 then player_y = 30 end

		if is_return() or active_edit then
			edit_blink = true
			cell_edit(player_x, player_y, active_edit);
		elseif key_num then
			c = tonumber(key_num)
			cell_set(player_x, player_y, c)
		end

		if not edit_blink then
			sprite.fill(sprite.screen(), player_x * 16, player_y * 16, 32, 32, "white");
		else
			sprite_draw(player_x, player_y, cell_get(player_x, player_y));
		end
		return
	end
	if nr_level == nr_levels and happy_end_spr_w then
		sprite.fill(sprite.screen(), (scr_w - happy_end_spr_w)/2, scr_h /2, happy_end_spr_w, scr_h / 2, "black")
	end

	if (player_x % 2 == 0) and (player_y % 2 == 0)  then
		player_movex, player_movey = 0, 0
		if is_key 'up' then
			player_movey = -1
		elseif is_key 'down' then
			player_movey = 1
		elseif is_key 'left' then
			player_movex = -1
		elseif is_key 'right' then
			player_movex = 1
		end
		if demo_mode then
			player_movex, player_movey = history_get()
		else
			history_add(player_movex, player_movey)
		end
		if player_movex ~= 0 or player_movey ~= 0 then
			local x, y = player_x + player_movex * 2, player_y + player_movey * 2
			if x <= 31 and y<= 31 and x >= 0 and y >= 0 then
				local c = cell_get(x, y)
				game_dispatch(c, x, y)
			else
				human_stop(x, y)
			end;
		else
			human_stop(x, y)
		end
	else -- inertion
		local x, y
		sprite_draw(player_x, player_y, BEMPTY)
		x, y = player_x - player_movex, player_y - player_movey
		local c = cell_get(x, y)
		if c == BHUMAN then
			cell_set(x, y, BEMPTY)
		elseif c == BGOLD or c == BSTONE then -- fix of the original game
			sprite_draw(x, y, c)
		end
		x, y =  player_x + player_movex, player_y + player_movey 
		c = cell_get(x, y)
		sprite_draw(x, y, c + 1)
		cell_set(x, y, BHUMAN)
		player_x, player_y = x, y
	end
	if menu_mode then
		return
	end
	fall();
	if menu_mode then
		return
	end
	enemy();

	if nr_level == nr_levels then
		happy_end_render()
	end

end

orig_save = game.save
game.save = function(s, ...)
	if demo_mode then
		return
	end
	_G["_selected_level_"..banks[nr_bank].name] = selected_level -- old selection
	return orig_save(s, ...)
end
global { nr_bank = 1 };

function bank_load()
	if nr_bank > #banks then
		nr_bank = 1
	end
	dofile (banks[nr_bank].file)
	nr_levels = #maps / 16
	print (nr_levels.." level(s) loaded...");
	local k,v 
	for k,v in ipairs(happy_end_map) do
		stead.table.insert(maps, v)
	end
	if not _G["_selected_level_"..banks[nr_bank].name] then
		_G["_selected_level_"..banks[nr_bank].name] = 0
	end
	nr_level = _G["_selected_level_"..banks[nr_bank].name]
	if nr_level >= nr_levels then
		nr_level = 0
	end
	selected_level = nr_level -- new selection
end

function bank_save()
	if nr_bank > #banks then
		return
	end
	local f = io.open(banks[nr_bank].file, "w")
	if not f then
		return
	end
	f:write(string.format("--$Name:%s\n", banks[nr_bank].title));
	local k,v
	if banks[nr_bank].title_i18n then
		for k, v in pairs(banks[nr_bank].title_i18n) do
			f:write(string.format("--$Name(%s):%s\n", 
				k, v));
		end
	end
	f:write(string.format("maps = {\n"))
	for k = 1, nr_levels do
		f:write(string.format("-- %d\n", k - 1));
		local n
		for n=1,16 do
			f:write(string.format('"%s",\n', maps[(k - 1) * 16 + n]))
		end
	end
	f:write(string.format("};\n"))
	f:close()
end

init = function()
	set_music_fading(500, 500)
	hook_keys('left', 'right', 'up', 'down', 'space', 'return', 'd', 'escape', 'e', '0', '1', '2', '3', '4', '5', '6', '7');
	load_sprites()
	load_sounds()
	offscreen = sprite.blank(scr_w, scr_h)
	banner = sprite.blank(scr_w, 32)
	sprite.fill(sprite.screen(), 'black');
	level_select = true
	banks_init();
end

start = function()
	bank_load()
	if menu_mode ~= 'level_select' and menu_mode ~= 'title' and not demo_mode and menu_mode ~= 'bank_select' then
		level_load()
		level_movein()
	else
		title_enter()
	end
end

dofile "i18n.lua"
dofile "menu.lua"

main.nam = '!!!';
main.dsc = function(s)
	p (_("warning:Please, go to settings and switch on own themes feature!"))
end
