--$Name:Miner Bold$
--$Version:0.2$
instead_version "2.0.0"
TIMER = 85
FAST_TIMER = 30
require "sprites"
require "sound"
require "timer"
require "kbd"
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
	for y = 1, 16 do
		map[y] = {}
		local row = maps[line + y]
		for x = 1, 16 do
			local c = string.sub(row, x, x);
			c = char2map[c]
			map[y][x] = c
			if c == BHUMAN then
				player_x = (x - 1) * 2
				player_y = (y - 1) * 2
				player_movex = 0;
				player_movey = 0;
			elseif c >= BHEART then --
				stead.table.insert(enemies, { x = (x - 1) * 2, y = (y - 1) * 2, dx = 0, dy = 0 })
			end
		end
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

game.kbd = function(s, down, key)

	if key == 'space' or key == 'return' then
		key_return = down
		return
	end

	if key == 'escape' or key == 'backspace' then
		if not title_mode then
			key_esc = down
			return true
		end
		key_esc = false
	end

	if key == 'd' then
		key_demo = down
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

global { level_in = false, level_out = false, level_select = false, title_mode = false }

level_reset = function(win, notitle)
	if win and not demo_mode then
		history_store(win)
	end
	sprite.copy(sprite.screen(), offscreen)
	level_out = 0
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
			bant = sprite.text(fn2, stead.string.format(_("tries:TRIES").." %d", st.die), 'red', 1)
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
	level_out = false
	level_select = false


	local st = level_stat()
	local bant
	if not demo_mode then
		bant = sprite.text(fn2, stead.string.format(_("level:LEVEL").." %d", nr_level + 1), 'red', 1)
	else
		bant = sprite.text(fn2, stead.string.format(_("demo:DEMO").." %d", nr_level + 1), 'red', 1)
	end
	local w, h = sprite.size(bant)
	sprite.fill(banner, 'black')
	sprite.draw(bant, banner, (scr_w - w) / 2, 0)
	sprite.free(bant)

	level_in = scr_h + h
	sound.play(sounds[SLEVELIN], 3)
	timer:set(FAST_TIMER)
end

level_ready = function()
	level_in = false
	level_out = false
	level_render(sprite.screen());
	timer:set(TIMER)
end

level_choose = function()
	level_select = true
	level_in = false
	level_out = false
	level_load()

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
		lev = sprite.text(fn, stead.string.format(_("tries:ПОПЫТОК").." %d", st.die), 'red', 1)
		local w, h = sprite.size(lev)
		sprite.draw(lev, offscreen, (scr_w - 256) / 2 + (256 - w) / 2, (scr_h - 256) / 2 + 256 + h / 2);
		sprite.free(lev)
	end
	sprite.copy(offscreen, sprite.screen())
	timer:set(FAST_TIMER / 2)
end
MAP_SPEED = 32

demo_enter = function()
	local l
	local ll = {}
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
	title_mode = false
end

game.timer = function(s)
	if title_mode then
		title_time = title_time + 1
		if title_time > 300 then
			title_time = 0
			demo_enter()
			return
		end
		if title_mode ~= true then
			title_mode = title_mode - 32
			if title_mode < 32 then title_mode = 32 end
			title_render(sprite.screen(), 0, title_mode);
		end
		if title_mode == 32 then
			title_mode = true
		end 
		if title_mode == true and is_anykey() then
			keys = {}
			title_mode = false
			nr_level = selected_level
			level_choose()
			sound.play(sounds[SPHASER], 3)
			return
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
		return
	end

	if is_esc() then
		title_enter()
		return
	end
	if level_in then
		local bw,bh = sprite.size(banner)
		if level_in < 0 then level_in = 0 end
		sprite.copy(banner, sprite.screen(), 0, level_in - bh)
		level_render(sprite.screen(), level_in)
		if level_in == 0 then
			level_ready()
			return
		end
		level_in = level_in - 8
		return
	end
	if level_out then
		local bw,bh = sprite.size(banner)

		if level_out >= scr_h + bh then level_out = scr_h + bh end
		sprite.fill(sprite.screen(), 0, level_out - 8 - bh, scr_h, level_out, 'black')
		sprite.copy(banner, sprite.screen(), 0, level_out - bh);
		sprite.copy(offscreen, sprite.screen(), 0, level_out)
		if level_out == scr_h + bh then
			level_movein()
			return
		end
		level_out = level_out + 8
		return
	end
	if level_select then
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
		end
		if level_select == true then
			if (is_key 'right' or is_key 'down') and nr_level < nr_levels - 1 then
				nr_level = nr_level + 1
				selected_level = nr_level
				level_select = -MAP_SPEED
			elseif (is_key 'left' or is_key 'up') and nr_level > 0 then
				nr_level = nr_level - 1
				selected_level = nr_level
				level_select = MAP_SPEED
			elseif is_return() then
				selected_level = nr_level
				sprite.fill(sprite.screen(), 'black')
				level_load()
				level_movein()
				return
			elseif is_demo() and history_check(nr_level) then
				sprite.fill(sprite.screen(), 'black')
				level_load()
				history_load()
				level_movein()
				level_after = level_choose
				demo_mode = true
				return
			end
			level_load()
		end
		return
	end
	game_loop()
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
--	prefs:store()
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
	local c = cell_get(player_x, player_y)
	if c ~= BHUMAN and c < 12 then
		level_stat().die = level_stat().die + 1
--		prefs:store()
		level_reset()
	end
	return xe, ye
end

level_stat = function()
	local st = prefs.stat[nr_level]
	if not st then
		prefs.stat[nr_level] = { }
		st = prefs.stat[nr_level]
	end
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
		level_reset()
		return
	end
	if nr_gold == 0 then -- or is_return() then
		-- completed
		if demo_mode then
			level_reset()
			return
		end
		level_stat().completed = level_stat().completed + 1
		if level_stat().score < nr_score then
			level_stat().score = nr_score
		end
--		prefs:store()
		local l = nr_level
		nr_level = nr_level + 1
		selected_level = nr_level
		if nr_level == nr_levels then
			-- lookup first undone
			local i
			for i=0,nr_levels - 1 do
				if not prefs.stat[i] or 
				    not prefs.stat[i].completed or 
				    prefs.stat[i].completed == 0 then
					nr_level = i
					break
				end
			end
		end
		if nr_level == nr_levels then
			-- todo game over
			nr_level = 0
			level_reset(l)
		else
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

history_check = function(nr)
	local p = instead_gamepath().."/demo"..tostring(nr + 1)
	local f = io.open(p, "r")
	if not f then
		p = instead_savepath().."/demo"..tostring(nr + 1)
		f = io.open(p, "r")
	end
	if not f then
		return false
	end
	f:close()
	return true
end

history_load = function()
	local p = instead_gamepath().."/demo"..tostring(nr_level + 1)
	local f = io.open(p, "r")
	if not f then
		p = instead_savepath().."/demo"..tostring(nr_level + 1)
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
	local p = instead_savepath().."/demo"..tostring(n + 1)
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
		end
		x, y =  player_x + player_movex, player_y + player_movey 
		c = cell_get(x, y)
		sprite_draw(x, y, c + 1)
		cell_set(x, y, BHUMAN)
		player_x, player_y = x, y
	end
	if level_out or title_mode or level_select then
		return
	end
	fall();
	if level_out or title_mode or level_select then
		return
	end
	enemy();
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
"    Порт игры под INSTEAD выполнен П.А. Косых в 2015 г.",
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
	local fw, fh = sprite.text_size(tfn)
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
	title_time = 0
	title_mode = scr_h
	timer:set(FAST_TIMER)
	level_in, level_out, level_select = false, false, false
	demo_mode = false
--	sound.stop(-1)
	sound.play(sounds[STRILL], 3)
	level_after = false
end
orig_save = game.save
game.save = function(s, ...)
	if demo_mode then
		return
	end
	return orig_save(s, ...)
end
init = function()
	hook_keys('left', 'right', 'up', 'down', 'space', 'return', 'd', 'escape');
	load_sprites()
	load_sounds()
	offscreen = sprite.blank(scr_w, scr_h)
	banner = sprite.blank(scr_w, 32)
	sprite.fill(sprite.screen(), 'black');
	level_select = true
end
start = function()
	if not level_select and not title_mode then
		level_load()
		level_movein()
	else
		title_enter()
	end
end
dofile "i18n.lua"
dofile "maps.lua"
