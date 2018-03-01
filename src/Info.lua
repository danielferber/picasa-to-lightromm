--[[----------------------------------------------------------------------------

ADOBE SYSTEMS INCORPORATED
 Copyright 2007 Adobe Systems Incorporated
 All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.

--------------------------------------------------------------------------------

Info.lua
Summary information for Hello World sample plug-in.

Adds menu items to Lightroom.

------------------------------------------------------------------------------]]

return {
	
	LrSdkVersion = 5.0,
	LrSdkMinimumVersion = 5.0,

	LrToolkitIdentifier = 'org.usefultoys.lr.picasa',

	LrPluginName = LOC "$$$/PicasaImport/PluginName=Picasa Import",
	
	-- Add the menu item to the File menu.
	
	LrExportMenuItems = {
		title = "Import Picasa",
		file = "ImportPicasaMenuItem.lua",
	},

	VERSION = { major=0, minor=1, revision=0, build=4, },

}


	
