local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'
local Picasa = require 'Picasa'

local logger = LrLogger('ImportPicasaMenuItem')
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

APPLY_ALWAYS = 1
APPLY_IF_NOT_SET = 0
APPLY_NEVER = nil
ConvertInfo = { rotate = {},
    star = { rating = 5, keyword = "Picasa-Star", colorLabel = 'red', pickStatus = 1 },
    crop = { keyword = "Picasa-Crop", apply = APPLY_ALWAYS },
    enhance = { keyword = "Picasa-Enhance", apply = APPLY_ALWAYS }}

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
        picasaKeyword = catalog:createKeyword("Picasa", {}, true, nil, true)
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
                logger:debug("Photo metadata: " .. Picasa.tableToString(metadata))
                logger:debug("Photo complete metadata: " .. Picasa.tableToString(photo:getRawMetadata()))
                logger:debug("Photo complete developmentsettings: " .. Picasa.tableToString(photo:getDevelopSettings()))

                if picasaInfo.star == true and ConvertInfo.star ~= nil and ConvertInfo.star.keyword ~= nil then
                    local keyword = catalog:createKeyword(ConvertInfo.star.keyword, {}, true, picasaKeyword, true)
                    logger:infof('Add keyword %s', ConvertInfo.star.keyword)
                    photo:addKeyword(keyword)
                end
                if picasaInfo.star == true and ConvertInfo.star ~= nil and ConvertInfo.star.rating ~= nil then
                    local newValue, oldValue = ConvertInfo.star.rating, metadata.rating
                    logger:infof('Set rating from %s to %s', (oldValue or 'n/a'), newValue)
                    photo:setRawMetadata('rating', newValue)
                end
                if picasaInfo.star == true and ConvertInfo.star ~= nil and ConvertInfo.star.colorLabel ~= nil then
                    local newValue, oldValue = ConvertInfo.star.colorLabel, metadata.colorNameForLabel
                    logger:infof('Set rating from %s to %s', (oldValue or 'n/a'), newValue)
                    photo:setRawMetadata('colorNameForLabel', newValue)
                end
                if picasaInfo.star == true and ConvertInfo.star ~= nil and ConvertInfo.star.pickStatus ~= nil then
                    local newValue, oldValue = ConvertInfo.star.pickStatus, metadata.pickStatus
                    logger:infof('Set pickStatus from %s to %s', (oldValue or 'n/a'), newValue)
                    photo:setRawMetadata('pickStatus', newValue)
                end

                if picasaInfo.crop ~= nil and ConvertInfo.crop ~= nil and ConvertInfo.crop.keyword ~= nil then
                    local keyword = catalog:createKeyword(ConvertInfo.crop.keyword, {}, true, picasaKeyword, true)
                    logger:infof('Add keyword %s', ConvertInfo.crop.keyword)
                    photo:addKeyword(keyword)
                end
                if picasaInfo.crop ~= nil and ConvertInfo.crop ~= nil and ConvertInfo.crop.apply ~= APPLY_NEVER then
                    local settings = photo:getDevelopSettings()
                    if ConvertInfo.crop.apply == APPLY_ALWAYS or (settings.CropBottom == nil and settings.CropLeft == nil and settings.CropRight == nil and settings.CropTop == nil) then
                        local newValue, oldValue = picasaInfo.crop, {left = settings.CropLeft, top = settings.CropTop, right = settings.CropRight, bottom = settings.CropBottom}
                        logger:infof('Set crop from %s to %s', Picasa.tableToString(oldValue), Picasa.tableToString(newValue))
                        settings.CropBottom = newValue.bottom
                        settings.CropLeft = newValue.left
                        settings.CropRight = newValue.right
                        settings.CropTop = newValue.top
                        photo:applyDevelopSettings(settings)
                    end
                end

                if picasaInfo.enhance ~= nil and ConvertInfo.enhance ~= nil and ConvertInfo.enhance.keyword ~= nil then
                    local keyword = catalog:createKeyword(ConvertInfo.enhance.keyword, {}, true, picasaKeyword, true)
                    logger:infof('Add keyword %s', ConvertInfo.enhance.keyword)
                    photo:addKeyword(keyword)
                end
                if picasaInfo.enhance == true and ConvertInfo.enhance ~= nil and ConvertInfo.enhance.apply ~= APPLY_NEVER then
                    local settings = photo:getDevelopSettings()
                    local newValue, oldValue = {brightness = true, contrast=true, exposure=true, shadows=true}, {Brightness = settings.AutoBrightness, contrast=settings.AutoContrast, exposure=settings.AutoExposure, shadows=settings.AutoShadows}
                    logger:infof('Set enhance from %s to %s', oldValue, newValue)
                    --[[settings.AutoBrightness = newValue.brightness
                    settings.AutoContrast = newValue.contrast
                    settings.AutoExposure = newValue.exposure
                    settings.AutoShadows = newValue.shadows]]
                    settings.AutoTone = true
                    photo:applyDevelopSettings(settings)
                end

            end)
        end
    end
end

logger:infof("Menu item activated at %s", os.date("%d/%m/%Y %X"))
LrTasks.startAsyncTask(task)
