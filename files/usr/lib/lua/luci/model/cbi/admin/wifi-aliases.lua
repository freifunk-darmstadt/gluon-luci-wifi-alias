local uci = luci.model.uci.cursor()

local ssid = uci:get('wireless', 'alias', 'ssid')
local f = SimpleForm("wifi alias", translate("WiFi alias"))


local s = f:section(SimpleSection, nil, translate((
		"This is not the SSID you are looking for.<br />You can do stupid stuff here.<br />"
)))


o = s:option(Flag, "enabled", translate("Enabled"))

local enabled = ((ssid and not uci:get('wireless', 'alias', 'disabled')))
o.default = (enabled and o.enabled or o.disabled)
o.rmempty = false

local o = s:option(Value, "ssid", translate("SSID"))
o:depends("enabled", 1)
o.default = ssid


function f.handle(self, state, data)
   if state == FORM_VALID then
      if data.enabled == 1 then
         uci:set('wireless', 'alias', 'ssid', ssid)
	 uci:set('wireless', 'alias', 'disabled', 0)
      else
	 uci:set('wireless', 'alias', 'disabled', 1)
      end
      uci:save('wireless')
      uci:commit('wireless')
   end
end

return f
