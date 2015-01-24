--$Name:Miner Bold$
--$Version:0.1$
instead_version "2.0.0"

require "sprites"
require "sound"
require "timer"
require "kbd"

sprites = {}
sounds = {}
global {
	nr_level = 0;
	map = {};
};

SDIE = 1
SFALL = 2
SCLICK = 3
SLEVELIN = 4

load_sounds = function()
	sounds[SDIE] = sound.load "snd/explode.ogg"
	sounds[SFALL] = sound.load "snd/fall.ogg"
	sounds[SCLICK] = sound.load "snd/click.ogg"
	sounds[SLEVELIN] = sound.load "snd/levelin.ogg"
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
		sprites[i] = sprite.scale(s, 2.0, 2.0, false)
		sprite.free(s)
	end
end

BEMPTY = 0
BGRASS = 1
BSTONE = 2
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

load_map = function()
	enemies = {};
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

render_map = function(where, offset)
	if not offset then offset = 0 end
	local y
	local x
	for y = 1,16 do
		local yy = 32 * (y - 1) + offset
		if yy >= 512 then
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

keys = {}

game.kbd = function(s, down, key)
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

global { level_in = false, level_out = false }

reset_level = function()
	sprite.copy(sprite.screen(), back_screen)
	level_out = 0
	load_map()
end

game.timer = function(s)
	if level_in then
		if level_in < 0 then
			level_in = 0
		end
		render_map(sprite.screen(), level_in)
		if level_in == 0 then
			level_in = false
			return
		end
		level_in = level_in - 8
		return
	end

	if level_out then
		if level_out >= 512 then
			level_out = 512
		end
		sprite.fill(sprite.screen(), 0, level_out - 8, 512, level_out, 'black')
		sprite.copy(back_screen, sprite.screen(), 0, level_out)
		if level_out == 512 then
			level_out = false
			level_in = 512
			sound.play(sounds[SLEVELIN])
--			nr_level = nr_level + 1
--			load_map()
			return
		end
		level_out = level_out + 8
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

iskey = function(n)
	if keys[1] == n then
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
	cell_set(xx, yy, BSTONE)
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
		reset_level()
	end
	return xe, ye
end
fall = function()
	local nr_gold = 0
	local x, y, c
	for y = 30,0,-2 do
		x = 0
		while x <= 30 do 
			c = cell_get(x, y)
			if c == BGOLD or c == BGOLD3 or c == BGOLD2 then
				nr_gold = nr_gold + 1
			end
			if c == BGOLD or c == BSTONE then
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
		print ("dec lives"..c)
		reset_level()
	end
	if nr_gold == 0 then
		nr_level = nr_level + 1
		reset_level()
	end
end

global { fall_stage = false };
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
	local c = cell_get(x, y)
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
		c = cell_get(x, y)
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
game_loop = function()
	if fall_stage then
		if fall_stage == true then
			fall();
			fall_stage = 1
		else
			enemy();
			fall_stage = false
		end
		return
	end
	fall_stage = true
	if (player_x % 2 == 0) and (player_y % 2 == 0)  then
		player_movex, player_movey = 0, 0
		if iskey 'up' then
			player_movey = -1
		elseif iskey 'down' then
			player_movey = 1
		elseif iskey 'left' then
			player_movex = -1
		elseif iskey 'right' then
			player_movex = 1
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
end

init = function()
	hook_keys('left', 'right', 'up', 'down');
	load_sprites()
	load_sounds()
	back_screen = sprite.blank(512, 512)
	load_map()
	level_in = 512
	sprite.fill(sprite.screen(), 'black');
	timer:set(30)
end
start = function()
	if not level_in then
		level_out = false
		level_in = 512
		load_map();
--		render_map(sprite.screen());
	elseif level_in == 512 then
		sound.play(sounds[SLEVELIN])
	end
end

dofile "maps.lua"

