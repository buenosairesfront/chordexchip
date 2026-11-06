-- chip_lane: una escenita animada por consola en el carril de abajo a la
-- izquierda (debajo del tracker): x 0..73, y 58..63 (6 filas).
-- Dibuja con G.px / G.rect (el acumulador por nivel del script) y,
-- para el prompt de DOS, con screen.text.
--
-- Todo sale de t (segundos), así que no guarda estado entre cuadros.

local L = {}
local X0, X1, Y0, Y1 = 0, 73, 58, 63
local G

local floor, sin, abs = math.floor, math.sin, math.abs

local function px(lv, x, y)
  x, y = floor(x), floor(y)
  if x >= X0 and x <= X1 and y >= Y0 and y <= Y1 then G.px(lv, x, y) end
end

-- rows: filas de arriba a abajo, "#" = prendido
local function spr(rows, x, y, lv)
  for yy = 1, #rows do
    local r = rows[yy]
    for xx = 1, #r do
      if r:byte(xx) == 35 then px(lv, x + xx - 1, y + yy - 1) end
    end
  end
end

-- ------------------------------------------------------------
-- NES: un plomero que corre; los bichos caminan al revés y él los salta
-- ------------------------------------------------------------
local RUN = {{".##.", "###.", ".##.", "#..#"}, {".##.", "###.", ".##.", ".##."}}
local GOOM = {{".##.", "####", "#..#"}, {".##.", "####", ".##."}}
local function nes(t)
  local span = X1 + 12
  local x = (t * 17) % span - 6
  local hop = 0
  for k = 0, 1 do
    local ex = X1 + 4 - ((t * 9 + k * span / 2) % span)
    spr(GOOM[floor(t * 4) % 2 + 1], ex, 61, 10)
    local d = abs((x + 2) - (ex + 2))
    if d < 7 then hop = math.max(hop, 2 * (1 - (d / 7) ^ 2)) end
  end
  local f = hop > 0.3 and 2 or (floor(t * 8) % 2 + 1)
  spr(RUN[f], x, 60 - floor(hop + 0.5), 15)
  -- monedas que titilan arriba de vez en cuando
  for k = 0, 2 do
    local cx = 14 + k * 22
    if floor(t * 3 + k) % 4 == 0 then px(12, cx, 58) end
  end
end

-- ------------------------------------------------------------
-- GB: caen piezas de 4 bloques hasta llenar el piso; la fila titila y se borra
-- ------------------------------------------------------------
local PIECES = {
  {"##", "##"}, {"###", ".#."}, {".##", "##."}, {"###", "#.."},
  {"####"}, {"###", "..#"}, {"##.", ".##"},
}
local GB_LAYOUT = {}
do
  local x, i = 0, 0
  while true do
    local p = PIECES[i % #PIECES + 1]
    local w = #p[1]
    if x + w - 1 > X1 then break end
    GB_LAYOUT[#GB_LAYOUT + 1] = {p = p, x = x}
    x = x + w
    i = i + 1
  end
end
local GB_DROP = 0.32
local function gb(t)
  local n = #GB_LAYOUT
  local cyc = n * GB_DROP + 1.0
  local u = t % cyc
  local k = floor(u / GB_DROP) + 1
  if k > n then
    -- piso lleno: titila y se borra
    if floor(u * 10) % 2 == 0 then
      for _, it in ipairs(GB_LAYOUT) do spr(it.p, it.x, 64 - #it.p, 15) end
    end
    return
  end
  for i = 1, k - 1 do
    local it = GB_LAYOUT[i]
    spr(it.p, it.x, 64 - #it.p, 9)
  end
  local it = GB_LAYOUT[k]
  local fr = (u % GB_DROP) / GB_DROP
  local rest = 64 - #it.p
  spr(it.p, it.x, Y0 + floor((rest - Y0) * fr + 0.5), 15)
end

-- ------------------------------------------------------------
-- C64: invasores que marchan; el cañón de abajo los va bajando de a uno
-- ------------------------------------------------------------
local INV = {{".###.", "#.#.#", "#####", ".#.#."}, {".###.", "#.#.#", "#####", "#...#"}}
local BOOM = {"#...#", "..#..", "#.#.#", "..#.."}
local KILL = 1.4
local function c64(t)
  local cyc = 4 * KILL + 1.2
  local u = t % cyc
  local step = floor(t * 4)
  local march = step % 28
  local ox = march < 14 and march or 28 - march
  local legs = step % 2 + 1
  local cx_target, shot
  for k = 1, 4 do
    local ix = 2 + ox + (k - 1) * 12
    local tk = k * KILL               -- cuándo le pega a éste
    if u < tk - 0.25 then
      spr(INV[legs], ix, 58, 11)
      if not cx_target then
        cx_target = ix + 1
        -- disparo en vuelo
        local s = tk - 0.25 - u
        if s < 0.25 then shot = {ix + 2, 58 + floor(s / 0.25 * 3) + 1} end
      end
    elseif u < tk then
      spr(BOOM, ix, 58, 15)
    end
  end
  local cx = cx_target or 30
  spr({".#.", "###"}, cx, 62, 15)
  if shot then px(15, shot[1], shot[2]) end
end

-- ------------------------------------------------------------
-- ATARI: el comecocos se come los puntitos con el fantasma atrás; al comer
-- la pastilla grande el fantasma se asusta y titila
-- ------------------------------------------------------------
local PAC = {
  {".###.", "###..", "##...", "###..", ".###."},
  {".###.", "####.", "##...", "####.", ".###."},
  {".###.", "#####", "#####", "#####", ".###."},
}
local PAC_SEQ = {1, 2, 3, 2}
local GHOST = {{".###.", "#.#.#", "#####", "#####", "#.#.#"},
               {".###.", "#.#.#", "#####", "#####", ".#.#."}}
local PELLET = 62
local function atari(t)
  local span = X1 + 26
  local x = (t * 16) % span - 6
  local mouth = x + 4
  for dx = 3, X1, 4 do
    if dx ~= PELLET and dx > mouth then px(9, dx, 61) end
  end
  if PELLET + 1 > mouth and floor(t * 4) % 2 == 0 then G.rect(15, PELLET, 60, 2, 2) end
  spr(PAC[PAC_SEQ[floor(t * 10) % 4 + 1]], x, 59, 15)
  local gx = x - 11
  local scared = mouth > PELLET + 1
  local glv = scared and (floor(t * 8) % 2 == 0 and 15 or 5) or 11
  spr(GHOST[floor(t * 6) % 2 + 1], gx, 59, glv)
end

-- ------------------------------------------------------------
-- MSX: la nave dispara a los bichos que entran ondulando desde la derecha
-- ------------------------------------------------------------
local SHIP = {"#....", "###..", "#####", "###..", "#...."}
local BUG = {{"#.#", ".#.", "#.#"}, {".#.", "###", ".#."}}
local SPAWN, BUG_V, SHOT_V, HIT_X, GUN_X = 1.2, 20, 60, 40, 6  -- impacto en y 60..61
local function msx(t)
  local ship_y = 59
  local k0 = floor(t / SPAWN)
  for k = k0 - 3, k0 do
    local ts = k * SPAWN
    local th = ts + (X1 - HIT_X) / BUG_V           -- impacto
    local tl = th - (HIT_X - GUN_X) / SHOT_V        -- disparo
    local hy = 59 + (k % 2)                         -- fila del bicho (59..60)
    if t >= ts and t < th then
      local bx = X1 - (t - ts) * BUG_V
      local by = hy + floor(sin((th - t) * 6) * 1.2 + 0.5)
      spr(BUG[floor(t * 6) % 2 + 1], bx, util.clamp(by, 58, 61), 11)
    elseif t >= th and t < th + 0.25 then
      local r = floor((t - th) * 12)
      px(15, HIT_X - r, hy - r + 1); px(15, HIT_X + 2 + r, hy - r + 1)
      px(15, HIT_X - r, hy + r + 1); px(15, HIT_X + 2 + r, hy + r + 1)
    end
    if t >= tl and t < th then
      local sx = GUN_X + (t - tl) * SHOT_V
      px(15, sx, hy + 1); px(15, sx + 1, hy + 1)
    end
    if t >= tl - 0.6 and t < th then ship_y = hy - 1 end
  end
  spr(SHIP, 1, util.clamp(ship_y, 58, 59), 15)
end

-- ------------------------------------------------------------
-- PCE: estrellas en dos planos pasando y la nave con la tobera encendida
-- ------------------------------------------------------------
local STARS = {}
for i = 1, 14 do
  STARS[i] = {x = (i * 37) % 74, y = 58 + (i * 5) % 6, fast = (i % 3 ~= 0)}
end
local PSHIP = {"##...", ".###.", "#####", ".###."}
local function pce(t)
  for _, s in ipairs(STARS) do
    local v = s.fast and 34 or 12
    local x = (s.x - t * v) % 74
    px(s.fast and 12 or 7, x, s.y)
  end
  local y = 59 + floor(sin(t * 2.2) * 1 + 0.5)
  spr(PSHIP, 6, y, 15)
  if floor(t * 12) % 2 == 0 then px(15, 5, y + 2) else px(10, 4, y + 2) end
  -- ráfagas cortas
  for k = 0, 2 do
    local sx = 11 + ((t * 70 + k * 22) % 64)
    px(15, sx, y + 2); px(15, sx + 1, y + 2)
  end
end

-- ------------------------------------------------------------
-- AMIGA: la pelota a cuadros rebota de pared a pared y gira
-- ------------------------------------------------------------
local BALL = {".###.", "#####", "#####", "#####", ".###."}
local function amiga(t)
  local span = X1 - 4
  local p = (t * 22) % (2 * span)
  local right = p < span
  local x = right and p or 2 * span - p
  local y = 59 - floor(abs(sin(t * 4.5)) * 1 + 0.5)
  local ph = floor(t * 10) * (right and 1 or -1)
  for yy = 1, 5 do
    for xx = 1, 5 do
      if BALL[yy]:byte(xx) == 35 then
        local on = ((xx + yy + ph) % 2 == 0)
        px(on and 15 or 6, x + xx - 1, y + yy - 1)
      end
    end
  end
  -- sombra en el piso
  if y < 59 then px(5, x + 2, 63) end
end

-- ------------------------------------------------------------
-- OPL: el prompt de DOS que tipea comandos
-- ------------------------------------------------------------
local CMDS = {"PLAY CHIP.MID", "SET BLASTER", "CD \\OPL", "DIR /W"}
local function opl(t)
  local per = 3.2
  local k = floor(t / per) % #CMDS + 1
  local u = t % per
  local cmd = CMDS[k]
  local n = math.min(#cmd, floor(u * 9))
  local txt = "C:\\>" .. cmd:sub(1, n)
  screen.font_face(1)
  screen.font_size(8)
  screen.level(11)
  screen.move(0, 63)
  screen.text(txt)
  local w = screen.text_extents(txt)
  if floor(t * 3) % 2 == 0 then G.rect(15, w + 1, 63, 3, 1) end
end

local SCENES = {NES = nes, GB = gb, C64 = c64, ATARI = atari, MSX = msx,
                PCE = pce, AMIGA = amiga, OPL = opl}

function L.init(g) G = g end

function L.draw(name, t)
  local f = SCENES[name]
  if f then f(t) end
end

return L
