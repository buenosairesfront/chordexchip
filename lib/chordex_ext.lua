-- chordex_ext.lua — arc y crow para la familia Chordex (el mismo archivo en
-- todos los Chordex). Si no hay arc ni crow conectados no hace nada: el
-- instrumento funciona igual que siempre.
--
-- arc (4 anillos): cada anillo mueve un parámetro del script y lo muestra
--   como una perilla (arco de 270°). El punto brillante late con el sonido.
-- crow:
--   IN1  altura en V/oct (0 V = C4)       IN2  gate: sube = toca, baja = suelta
--   OUT1 tónica del acorde en V/oct       OUT2 envolvente (0-8 V, ataque/release
--                                              del script)
--   OUT3 LFO a tempo (en ABNT: el movimiento)  OUT4 pulso en cada acorde o paso
--
-- Uso desde el script:
--   local ext = include("lib/chordex_ext")
--   ext.add_params()                       -- después de add_params()
--   ext.init{rings = {"cutoff", "res", "arp_rate", "space"},
--            env = function() return atk, dec, sus, rel end,
--            beat = beat_seconds, on = on_note_on, off = on_note_off,
--            lfo = function() return periodo_s, voltios end,   -- opcional
--            level = function() return 0..1 end}               -- opcional
--   ext.chord(nota, vel) / ext.pulse() / ext.release() desde el sonido.

local X = {}
local cfg = {rings = {}}
local A                      -- vport del arc
local acc = {0, 0, 0, 0}     -- acumulador para parámetros de pasos
local arc_metro, lfo_metro
local lfo_sent = ""
local gate_hi = false
local in_volts = 0
local crow_note = nil

local function pv(id) return params:get(id) end

-- ---------- crow (todo envuelto: si no hay crow no pasa nada) ----------

local function crow_ok()
  return crow ~= nil and params.lookup["crow_on"] ~= nil and pv("crow_on") == 2
end

local function csend(fn)
  if not crow_ok() then return end
  pcall(fn)
end

local function setup_crow()
  if not crow_ok() then return end
  pcall(function()
    crow.input[1].stream = function(v) in_volts = v end
    crow.input[1].mode("stream", 0.01)
    crow.input[2].change = function(s)
      if s == 1 or s == true then
        if gate_hi then return end
        gate_hi = true
        local n = util.clamp(60 + math.floor(in_volts * 12 + 0.5), 0, 127)
        crow_note = n
        if cfg.on then cfg.on(n, 100) end
      else
        if not gate_hi then return end
        gate_hi = false
        if crow_note and cfg.off then cfg.off(crow_note) end
        crow_note = nil
      end
    end
    crow.input[2].mode("change", 1.0, 0.1, "both")
    crow.output[4].action = "pulse(0.01, 5)"
    lfo_sent = ""
  end)
end

function X.chord(note, vel)
  csend(function()
    crow.output[1].volts = (note - 60) / 12
    local a, d, s, r = 0.01, 1.5, 0.7, 0.9
    if cfg.env then a, d, s, r = cfg.env() end
    crow.output[2].action = string.format("{held{to(8,%.3f),to(%.2f,%.3f)},to(0,%.3f)}",
      math.max(0.001, a), 8 * util.clamp(s, 0, 1), math.max(0.01, d), math.max(0.01, r))
    crow.send("output[2](true)")
    crow.output[4].execute()
  end)
end

function X.pulse()
  csend(function() crow.output[4].execute() end)
end

function X.release()
  csend(function() crow.send("output[2](false)") end)
end

local function update_lfo()
  if not crow_ok() then return end
  local per, volts = 4 * (cfg.beat and cfg.beat() or clock.get_beat_sec()), 5
  if cfg.lfo then per, volts = cfg.lfo() end
  local key = string.format("%.3f %.2f", per, volts)
  if key == lfo_sent then return end
  lfo_sent = key
  pcall(function()
    if volts > 0.01 then
      crow.output[3].action = string.format("lfo(%.4f, %.2f)", math.max(0.02, per), volts)
      crow.output[3].execute()
    else
      crow.output[3].action = "to(0, 0.1)"
      crow.output[3].execute()
    end
  end)
end

-- ---------- arc ----------

local function norm(id)
  local p = params:lookup_param(id)
  if not p then return 0 end
  if p.t == 3 or p.t == 5 then return params:get_raw(id) end
  if p.t == 2 then return (pv(id) - 1) / math.max(1, #p.options - 1) end
  if p.t == 1 then return (pv(id) - p.min) / math.max(1, p.max - p.min) end
  return 0
end

local function arc_delta(n, d)
  local id = cfg.rings[n]
  if not id or not params.lookup[id] then return end
  local p = params:lookup_param(id)
  if p.t == 3 or p.t == 5 then
    params:delta(id, d * 0.2)
  else
    -- opciones y números: un paso cada tantos ticks
    acc[n] = acc[n] + d
    if math.abs(acc[n]) >= 12 then
      params:delta(id, acc[n] > 0 and 1 or -1)
      acc[n] = 0
    end
  end
end

local function arc_redraw()
  if not (A and A.device) then return end
  local lvl = cfg.level and util.clamp(cfg.level(), 0, 1) or 0
  A:all(0)
  for n = 1, 4 do
    local id = cfg.rings[n]
    if id and params.lookup[id] then
      -- perilla: de la posición 40 (abajo a la izquierda) 48 leds en sentido horario
      local v = util.clamp(norm(id), 0, 1)
      local head = math.floor(v * 47 + 0.5)
      for k = 0, 47 do
        local led = (40 + k) % 64 + 1
        if k < head then A:led(n, led, 5)
        elseif k == head then A:led(n, led, math.floor(10 + 5 * lvl + 0.5))
        else A:led(n, led, 1) end
      end
    end
  end
  A:refresh()
end

-- ---------- params / init ----------

function X.add_params()
  params:add_separator("chordex_ext", "ARC / CROW")
  params:add_option("crow_on", "crow (entradas y salidas)", {"no", "sí"}, 2)
  params:set_action("crow_on", function(v)
    if v == 2 then setup_crow() end
  end)
end

function X.init(c)
  cfg = c or cfg
  cfg.rings = cfg.rings or {}
  pcall(function()
    A = arc.connect()
    A.delta = arc_delta
  end)
  arc_metro = metro.init(arc_redraw, 1 / 15, -1)
  arc_metro:start()
  lfo_metro = metro.init(update_lfo, 1, -1)
  lfo_metro:start()
  -- crow puede conectarse después de cargar el script
  if crow then
    local prev = crow.add
    crow.add = function(...)
      if prev then pcall(prev, ...) end
      setup_crow()
    end
  end
  setup_crow()
end

function X.cleanup()
  if arc_metro then arc_metro:stop() end
  if lfo_metro then lfo_metro:stop() end
  if A and A.device then pcall(function() A:all(0); A:refresh() end) end
end

return X
