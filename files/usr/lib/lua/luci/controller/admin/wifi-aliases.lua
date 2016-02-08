module("luci.controller.admin.wifi-aliases", package.seeall)

function index()
	entry({"admin", "wifi-aliases"}, cbi("admin/wifi-aliases"), _("WiFi Aliases"), 21)
end
