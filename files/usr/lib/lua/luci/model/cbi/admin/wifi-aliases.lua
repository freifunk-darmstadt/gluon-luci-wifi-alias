-- TODO: add ability to remove data aliases
-- TODO: add ability to enforce a static pre-/postfix for the SSIDs

local uci = luci.model.uci.cursor()
local f = SimpleForm("wifi alias", translate("WiFi alias"))

---- add aliases
local s = f:section(SimpleSection, nil, translate((
  "This is not the SSID you are looking for.<br />You can do stupid stuff here.<br />"
)))

-- checkbox to create a new alias
local o = s:option(Flag, "add", translate("Add a new alias"))
o.default = false
o.rmempty = false

-- text input for the new alias SSID
o = s:option(Value, "ssid", translate("Name of the network (SSID)"))
o:depends("add", 1)
o.default = ""


---- delete aliases
local s2 = f:section(SimpleSection, translate("Delete Aliases"), translate('Check all aliases you want to delete.'))

-- get all existing aliases
local aliases = {}
uci:foreach('wireless', 'wifi-iface',
  function(s)
    local iface_ssid = uci:get('wireless', s['.name'], 'ssid')
    if iface_ssid and string.sub(s['.name'], 1, 5) == 'alias' and not aliases[iface_ssid] then
      table.insert(aliases, iface_ssid)
      aliases[iface_ssid] = true
    end
  end)

-- create a checkbox for all existing aliases
for j, alias in ipairs(aliases) do
  s2:option(Flag, "del_"..alias, alias)
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

-- add an alias with the given SSID
local function add_alias(ssid)
  -- get hardware radios
  local radios = get_radios()

  for i, radio in ipairs(radios) do
    local id = #aliases + 1
    local client = 'alias' .. id .. '_' .. radio

    uci:delete('wireless', client)
    uci:section('wireless', 'wifi-iface', client,
      {
        device = radio,
        network = 'client',
        mode = 'ap',
        ssid = ssid,
      }
    )
  end
end

-- handle POST requests
function f.handle(self, state, data)
   if state == FORM_VALID then
      if data.add == '1' then
         --uci:set('wireless', 'alias_ssid', data.ssid)
         add_alias(data.ssid)
         -- uci:set('wireless', 'alias_disabled', 0)
      else
        -- uci:set('wireless', 'alias_disabled', 1)
      end
      uci:save('wireless')
      uci:commit('wireless')
   end
end

return f
