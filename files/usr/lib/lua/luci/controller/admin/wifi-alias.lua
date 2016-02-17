module("luci.controller.admin.wifi-alias", package.seeall)

function index()
	entry({"admin", "wifi-alias"}, cbi("admin/wifi-alias"), _("WiFi Alias"), 21)
end
