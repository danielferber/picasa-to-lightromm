return {
    LrSdkVersion = 5.0,
    LrSdkMinimumVersion = 5.0,
    LrToolkitIdentifier = 'org.usefultoys.lr.picasa',
    LrPluginName = LOC "$$$/PicasaImport/PluginName=Picasa Import",

    -- Add the menu item to the File menu.

    LrExportMenuItems = {
        {
            title = "Step 1) Import Star, orientation.",
            file = "ImportPicasaStep1.lua",
        }, {
            title = "Step 2) Import crop, 'feeling lucky' and other edits",
            file = "ImportPicasaStep2.lua",
        }, {
            title = "Log settings",
            file = "LogSettings.lua",
        },
    },

    LrMetadataProvider = 'MetadataProvider.lua',
    LrMetadataTagsetFactory = 'MetadataTagsetFactory.lua',

    sectionsForTopOfDialog = function( viewFactory, propertyTable )
    end,
    sectionsForBottomOfDialog = function( viewFactory, propertyTable )
    end,
    VERSION = { major = 0, minor = 1, revision = 0, build = 4, },
}


	
