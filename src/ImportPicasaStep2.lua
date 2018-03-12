local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'
local ConvertInfo = require 'ConvertInfo'
local Picasa = require 'Picasa'
local inspect = require 'inspect'
local LrPathUtils = import 'LrPathUtils'

local logger = LrLogger('ImportPicasaStep2')
logger:enable("logfile")

function Picasa.logBridge(level, message, lineNumber)
    if lineNumber == nil then
        if (level == Picasa.INFO) then
            logger:info(message)
        elseif (level == Picasa.DEBUG) then
            logger:debug(message)
        elseif (level == Picasa.WARN) then
            logger:warn(message)
        elseif (level == Picasa.ERROR) then
            logger:error(message)
        elseif (level == Picasa.TRACE) then
            logger:trace(message)
        end
    else
        if (level == Picasa.INFO) then
            logger:info(lineNumber .. ': ' .. message)
        elseif (level == Picasa.DEBUG) then
            logger:debug(lineNumber .. ': ' .. message)
        elseif (level == Picasa.WARN) then
            logger:warn(lineNumber .. ': ' .. message)
        elseif (level == Picasa.ERROR) then
            logger:error(lineNumber .. ': ' .. message)
        elseif (level == Picasa.TRACE) then
            logger:trace(lineNumber .. ': ' .. message)
        end
    end
end

function Picasa.directoryPath(path)
    return LrPathUtils.parent(path)
end

function Picasa.childPath(path, child)
    return LrPathUtils.child(path, child)
end

local task = function(context)
    local catalog = LrApplication.activeCatalog()
    logger:info("Lightroom version: " .. LrApplication.versionString())
    logger:info("Catalog path: " .. catalog:getPath())

    local photos = catalog:getTargetPhotos()
    if photos == nil or #photos == 0 then
        logger:info("No photo selected. Exit.")
        return
    end
    logger:info("Number of selected photos: " .. tostring(#photos))

    local picasaKeyword
    catalog:withWriteAccessDo("Import Picasa", function(context)
        picasaKeyword = catalog:createKeyword(ConvertInfo.rootKeyword, {}, true, nil, true)
    end)

    local photosMetadata = catalog:batchGetRawMetadata(photos, { 'path', 'isVideo', 'rating', 'orientation', 'colorNameForLabel', 'pickStatus' })
    for photo, metadata in pairs(photosMetadata) do
        local directory = LrPathUtils.parent(metadata.path)
        if Picasa[directory] == nil then
            Picasa.loadIniFile(directory)
        end

        local picasaInfo = Picasa[metadata.path]
        if picasaInfo == nil then
            logger:infof("Photo %s: Picasa edits unavailable.", metadata.path)
        else
            catalog:withWriteAccessDo("Import Picasa", function(context)

                logger:infof("Photo %s: Picasa edits available.", metadata.path)
                local settings = photo:getDevelopSettings()
--                logger:debug("Photo metadata: " .. inspect(metadata))
                logger:debug("Photo settings: " .. inspect(settings))
                logger:debug("Picasa metadata: " .. inspect(picasaInfo))
                local applySettings = false

                if picasaInfo.crop ~= nil and ConvertInfo.crop ~= nil and ConvertInfo.crop.keyword ~= nil then
                    local name = ConvertInfo.crop.keyword
                    local keyword = catalog:createKeyword(name, {}, true, picasaKeyword, true)
                    logger:infof('Add keyword %s', name)
                    photo:addKeyword(keyword)
                end
                if picasaInfo.crop ~= nil and ConvertInfo.crop ~= nil and ConvertInfo.crop.apply == true then
                    local newValue = { CropTop = picasaInfo.crop.top, CropLeft = picasaInfo.crop.left, CropBottom = picasaInfo.crop.bottom, CropRight = picasaInfo.crop.right }
                    local oldValue = { CropTop = settings.CropTop, CropLeft = settings.CropLeft, CropBottom = settings.CropBottom, CropRight = settings.CropRight }
                    if newValue.CropLeft ~= settings.CropLeft
                            or newValue.CropTop ~= settings.CropTop
                            or newValue.CropRight ~= settings.CropRight
                            or newValue.CropBottom ~= settings.CropBottom then
                        logger:infof('Set Crop* from %s to %s', inspect(oldValue, { newline = '', indent = "" }), inspect(newValue, { newline = '', indent = "" }))
                        settings.CropTop = newValue.CropTop
                        settings.CropBottom = newValue.CropBottom
                        settings.CropLeft = newValue.CropLeft
                        settings.CropRight = newValue.CropRight
                        applySettings = true
                    else
                        logger:infof('Keep Crop* %s', inspect(oldValue, { newline = '', indent = "" }))
                    end
                end

                if picasaInfo.enhance ~= nil and ConvertInfo.enhance ~= nil and ConvertInfo.enhance.keyword ~= nil then
                    local name = ConvertInfo.enhance.keyword
                    local keyword = catalog:createKeyword(name, {}, true, picasaKeyword, true)
                    logger:infof('Add keyword %s', name)
                    photo:addKeyword(keyword)
                end
                if (picasaInfo.enhance == true or picasaInfo.autolight == true ) and ConvertInfo.enhance ~= nil and ConvertInfo.enhance.apply == true then
                    local newValue, oldValue = true, settings.AutoTone
                    if newValue ~= oldValue then
                        logger:infof('Set AutoTone from %s to %s', oldValue, newValue)
                        settings.AutoTone = newValue
                        applySettings = true
                    else
                        logger:infof('Keep AutoTone %s', (oldValue or 'n/a'))
                    end
                end

                if picasaInfo.blackWhite ~= nil and ConvertInfo.blackWhite ~= nil and ConvertInfo.blackWhite.keyword ~= nil then
                    local name = ConvertInfo.blackWhite.keyword
                    local keyword = catalog:createKeyword(name, {}, true, picasaKeyword, true)
                    logger:infof('Add keyword %s', name)
                    photo:addKeyword(keyword)
                end
                if picasaInfo.blackWhite == true and ConvertInfo.blackWhite ~= nil and ConvertInfo.blackWhite.apply == true then
                    local newValue, oldValue = true, settings.ConvertToGrayscale
                    if newValue ~= oldValue then
                        logger:infof('Set ConvertToGrayscale from %s to %s', oldValue, newValue)
                        settings.ConvertToGrayscale = newValue
                        applySettings = true
                    else
                        logger:infof('Keep ConvertToGrayscale %s', (oldValue or 'n/a'))
                    end
                end

                if picasaInfo.autolight == true and ConvertInfo.autolight ~= nil and ConvertInfo.autolight.apply == true then
                    local newValue, oldValue = true, settings.AutoContrast
                    if newValue ~= oldValue then
                        logger:infof('Set AutoContrast from %s to %s', oldValue, newValue)
                        settings.AutoContrast = newValue
                        applySettings = true
                    else
                        logger:infof('Keep AutoContrast %s', (oldValue or 'n/a'))
                    end
                end

                if picasaInfo.autolight == true and ConvertInfo.autolight ~= nil and ConvertInfo.autolight.apply == true then
                    local newValue, oldValue = true, settings.AutoExposure
                    if newValue ~= oldValue then
                        logger:infof('Set AutoExposure from %s to %s', oldValue, newValue)
                        settings.AutoExposure = newValue
                        applySettings = true
                    else
                        logger:infof('Keep AutoExposure %s', (oldValue or 'n/a'))
                    end
                end

                if applySettings then
                    photo:applyDevelopSettings(settings)
                end
            end)
        end
    end
end

logger:infof("Menu item activated at %s", os.date("%d/%m/%Y %X"))
LrTasks.startAsyncTask(task)
