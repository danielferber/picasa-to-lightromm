local LrLogger = import 'LrLogger'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'
local ConvertInfo = require 'ConvertInfo'
local Picasa = require 'Picasa'
local inspect = require 'inspect'
local LrPathUtils = import 'LrPathUtils'
local LrProgressScope = import 'LrProgressScope'

local logger = LrLogger('ImportPicasaStep1')
logger:enable {fatal = "logfile", error = "logfile", warn = "logfile", info = "logfile"}

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


    local progress = LrProgressScope({ title = "Import Star, orientation..." })
    progress:setCancelable(true)
    progress:setCaption("Import Star, orientation...")
    local progressDone = 0
    local progressTotal = #photos
    local photosMetadata = catalog:batchGetRawMetadata(photos, { 'path', 'rating', 'pickStatus', 'orientation', 'colorNameForLabel' })
    for photo, metadata in pairs(photosMetadata) do

        if progress:isCanceled() then return end

        local directory = LrPathUtils.parent(metadata.path)

        if Picasa[directory] == nil then
            progress:setCaption("Read Picasa file...")
            progressTotal = progressTotal + 10
            progress:setPortionComplete(progressDone, progressTotal)
            Picasa.loadIniFile(directory)
            progressDone = progressDone + 10
            progress:setCaption("Import Star, orientation...")
        end

        local picasaInfo = Picasa[metadata.path]
        if picasaInfo == nil then
            logger:infof("Photo %s: Picasa edits unavailable.", metadata.path)
        else
            catalog:withWriteAccessDo("Import Picasa - Step 1", function(context)
                logger:infof("Photo %s: Picasa edits available.", metadata.path)
                logger:debug("Photo metadata: " .. inspect(metadata))
                logger:debug("Picasa metadata: " .. inspect(picasaInfo))

                if picasaInfo.star == true and ConvertInfo.star ~= nil and ConvertInfo.star.keyword ~= nil then
                    local name = ConvertInfo.star.keyword
                    local keyword = catalog:createKeyword(name, {}, true, picasaKeyword, true)
                    logger:infof('Add keyword %s', name)
                    photo:addKeyword(keyword)
                end
                if picasaInfo.star == true and ConvertInfo.star ~= nil and ConvertInfo.star.rating ~= nil then
                    local newValue, oldValue = ConvertInfo.star.rating, metadata.rating
                    if newValue ~= oldValue then
                        logger:infof('Set rating from %s to %s', (oldValue or 'n/a'), newValue)
                        photo:setRawMetadata('rating', newValue)
                    else
                        logger:infof('Keep rating %s', (oldValue or 'n/a'))
                    end
                end
                if picasaInfo.star == true and ConvertInfo.star ~= nil and ConvertInfo.star.colorLabel ~= nil then
                    local newValue, oldValue = ConvertInfo.star.colorLabel, metadata.colorNameForLabel
                    if newValue ~= oldValue then
                        logger:infof('Set color from %s to %s', (oldValue or 'n/a'), newValue)
                        photo:setRawMetadata('colorNameForLabel', newValue)
                    else
                        logger:infof('Keep color %s', (oldValue or 'n/a'))
                    end
                end
                if picasaInfo.star == true and ConvertInfo.star ~= nil and ConvertInfo.star.pickStatus ~= nil then
                    local newValue, oldValue = ConvertInfo.star.pickStatus, metadata.pickStatus
                    if newValue ~= oldValue then
                        logger:infof('Set pickStatus from %s to %s', (oldValue or 'n/a'), newValue)
                        photo:setRawMetadata('pickStatus', newValue)
                    else
                        logger:infof('Keep pickStatus %s', (oldValue or 'n/a'))
                    end
                end

                if picasaInfo.rotate ~= nil and ConvertInfo.rotate ~= nil then
                    local newValue
                    if picasaInfo.rotate == 1 then newValue = 'BC'
                    elseif picasaInfo.rotate == 2 then newValue = 'CD'
                    elseif picasaInfo.rotate == 3 then newValue = 'DA'
                    end
                    local oldValue = metadata.orientation
                    if ConvertInfo.rotate.keyword90 ~= nil and
                            ((oldValue == 'AB' and newValue == 'BC')
                                    or (oldValue == 'BC' and newValue == 'CD')
                                    or (oldValue == 'CD' and newValue == 'DA')
                                    or (oldValue == 'DA' and newValue == 'AD')) then
                        local name = ConvertInfo.rotate.keyword90
                        local keyword = catalog:createKeyword(name, {}, true, picasaKeyword, true)
                        logger:infof('Requires setting orientation manually from %s to %s: add keyword %s', oldValue, newValue, name)
                        photo:addKeyword(keyword)
                    elseif ConvertInfo.rotate.keyword180 ~= nil and
                            ((oldValue == 'AB' and newValue == 'CD')
                                    or (oldValue == 'BC' and newValue == 'DA')
                                    or (oldValue == 'CD' and newValue == 'AD')
                                    or (oldValue == 'DA' and newValue == 'BC')) then
                        local name = ConvertInfo.rotate.keyword180
                        local keyword = catalog:createKeyword(name, {}, true, picasaKeyword, true)
                        logger:infof('Requires setting orientation manually from %s to %s: add keyword %s', oldValue, newValue, name)
                        photo:addKeyword(keyword)
                    elseif ConvertInfo.rotate.keyword270 ~= nil and
                            ((oldValue == 'AB' and newValue == 'DA')
                                    or (oldValue == 'BC' and newValue == 'AD')
                                    or (oldValue == 'CD' and newValue == 'BC')
                                    or (oldValue == 'DA' and newValue == 'CD')) then
                        local name = ConvertInfo.rotate.keyword270
                        local keyword = catalog:createKeyword(name, {}, true, picasaKeyword, true)
                        logger:infof('Requires setting orientation manually from %s to %s: add keyword %s', oldValue, newValue, name)
                        photo:addKeyword(keyword)
                    else
                        logger:infof('Keep orientation %s', oldValue)
                    end
                end
            end)
        end
        progressDone = progressDone + 1
        progress:setPortionComplete(progressDone, progressTotal)
    end
    progress:done()
end

logger:infof("Menu item activated at %s", os.date("%d/%m/%Y %X"))
LrTasks.startAsyncTask(task)
