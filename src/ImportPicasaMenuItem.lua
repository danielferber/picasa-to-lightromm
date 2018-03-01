local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'

local logger = LrLogger('importPicasaMenuItem')

logger:enable("logfile")
logger:info("Menu item activated.")

logger:info("Lightroom version: " .. LrApplication.versionString())


LrTasks.startAsyncTask(function(context)
    local catalog = LrApplication.activeCatalog()
    logger:info("Catalog path: " .. catalog:getPath())

    local targetPhoto = catalog:getTargetPhoto()
    if targetPhoto == nil then
        logger:info("No photo selected. Exit.")
        return
    end
    if not targetPhoto:checkPhotoAvailability() then
        logger:info("Photo not available. Exit.")
        return
    end
    local photoPath = targetPhoto:getRawMetadata("path")
    logger:info("Photo at " .. photoPath)
    local directory = LrPathUtils.parent(photoPath)
    local picasaPath = LrPathUtils.child(directory, '.picasa.ini')
    logger:info("Picasa at " .. picasaPath)

    if LrFileUtils.exists(picasaPath) ~= 'file' then
        logger:info("No picasa file available. Exit.")
        return
    end

    local picasaFiles = {}


    local file = io.open(filename)
    io.close(file)
    local line = nil


    local function tryHeader()
        return line:match('^%s*([.+])%s*$')
    end

    while (line == nil) do
        skipComments()

    end
end)

logger:info("END")