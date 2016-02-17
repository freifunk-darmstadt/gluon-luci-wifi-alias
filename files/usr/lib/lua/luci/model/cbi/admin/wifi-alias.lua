local uci = luci.model.uci.cursor()
local f = SimpleForm("wifi alias", translate("WiFi alias"))

-- we only allow to add one alias in the UI
local primary_alias_id = 0

-- enforce pre- and postfixes for the custom SSID
local prefix = ''
local postfix = ' (Freifunk)'

-- get all existing aliases
local function get_aliases()
  local aliases = {}
  uci:foreach('wireless', 'wifi-iface',
    function(s)
      local iface_ssid = uci:get('wireless', s['.name'], 'ssid')
      if iface_ssid and string.sub(s['.name'], 1, 5) == 'alias' and not aliases[iface_ssid] then
        table.insert(aliases, iface_ssid)
        aliases[iface_ssid] = true
      end
  end)
  return aliases
end

-- get all existing radio devices
local function get_radios()
  local radios = {}

  uci:foreach('wireless', 'wifi-device',
    function(s)
      table.insert(radios, s['.name'])
  end)
  return radios
end

-- get the SSID of the primary alias
local function get_primary_alias_ssid()
  -- get hardware radios
  local radios = get_radios()

  for i, radio in ipairs(radios) do
    local iface = 'alias' .. primary_alias_id .. '_' .. radio
    return uci:get('wireless', iface, 'ssid_plain')
  end
end

-- add the alias with the given SSID
local function set_alias(ssid)
  -- get hardware radios
  local radios = get_radios()

  for i, radio in ipairs(radios) do
    local iface = 'alias' .. primary_alias_id .. '_' .. radio
    uci:delete('wireless', iface)
    uci:section('wireless', 'wifi-iface', iface,
      {
        device = radio,
        network = 'client',
        mode = 'ap',
        ssid = prefix..ssid..postfix,
        ssid_plain = ssid,
      }
    )
  end
end

-- remove the alias
local function remove_alias()
  -- get hardware radios
  local radios = get_radios()

  for i, radio in ipairs(radios) do
    local iface = 'alias' .. primary_alias_id .. '_' .. radio
    uci:delete('wireless', iface)
  end
end

----- ----- -----
local ssid = get_primary_alias_ssid()

local s = f:section(SimpleSection, nil, translate((
  "Here you <strong>cannot</strong> create a private network.<br />A wifi alias is an additional name for the <strong>public</strong> wifi network (Freifunk)."
)))

-- checkbox to create a new alias
local o = s:option(Flag, "enable_alias", translate("Enable SSID alias"))
o.default = (not not ssid) and o.enabled or o.disabled
o.rmempty = false

-- text input for the new alias SSID
o = s:option(Value, "ssid", translate("Name of the network (SSID)"),
             'max.'..(32 - string.len(prefix) - string.len(postfix))..
             ' characters')
o.maxlength = (32 - string.len(prefix) - string.len(postfix))
o.default = ssid or ""
o.rmempty = false
o:depends("enable_alias", '1')

-- handle POST requests
function f.handle(self, state, data)
  if state == FORM_VALID then
    -- set/remove alias
    if data.enable_alias == '1' then
      local ssid = string.sub(data.ssid, 1,
                              (32 - string.len(prefix) - string.len(postfix)))
      set_alias(ssid)
    elseif data.enable_alias == '0' then
      remove_alias()
    end

    -- save the changes
    uci:save('wireless')
    uci:commit('wireless')
  end
end

return f
