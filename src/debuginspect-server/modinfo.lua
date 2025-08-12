name = "Debug Inspect (Server)"
description = [[Server integration for Debug Inspect, enables you to view server-side objects.

NOTES:
 - PLEASE READ: You should only use this locally or with servers/clients you trust, this mod does remote lua execution!
 - Does not work in local caveless worlds (since everything is accessible from client-side, you won't need this).
 - Does not show child tables's key count, because it only fetches 1 level at a time.
 - Does not support editing values directly in remote tables.]]
author = "gibbert"
version = "0.1"
api_version = 10

rotwood_compatible = false
dont_starve_compatible = false
dst_compatible = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"