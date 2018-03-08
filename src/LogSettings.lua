local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'
local inspect = require 'inspect'

local logger = LrLogger('LogSettingsMenuItem')
logger:enable("logfile")

local task = function(context)
    local catalog = LrApplication.activeCatalog()

    local photo = catalog:getTargetPhoto()
    if photo == nil then
        logger:info("No photo selected. Exit.")
        return
    end

    logger:info("Photo complete raw metadata: " .. inspect(photo:getRawMetadata()))
    logger:info("Photo complete development settings: " .. inspect(photo:getDevelopSettings()))
end

logger:infof("Menu item activated at %s", os.date("%d/%m/%Y %X"))
LrTasks.startAsyncTask(task)
