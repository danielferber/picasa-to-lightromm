--
-- Created by IntelliJ IDEA.
-- User: x7ws
-- Date: 01/03/2018
-- Time: 10:25
-- To change this template use File | Settings | File Templates.
--
local Picasa = {}

Picasa.ERROR = -2
Picasa.WARN = -1
Picasa.INFO = 0
Picasa.DEBUG = 1
Picasa.TRACE = 2

--- Split a string into a list of strings using a separator character.
-- @param sep Separator character
-- @return List of strings
local function split(str, sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

--- Helper method to log a message.
-- @param level Log level (INFO, DEBUG, ...)
-- @param message Log messagem. It may contain placeholders for string.format().
-- @param ... Extra params for string.format().
local function log(level, message, ...)
    if arg == nil then
        Picasa.logBridge(level, message)
    else
        Picasa.logBridge(level, string.format(message, unpack(arg)))
    end
end

function val_to_str(v)
    if "string" == type(v) then
        v = string.gsub(v, "\n", "\\n")
        if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v, '"', '\\"') .. '"'
    else
        return "table" == type(v) and tostring(v) or
                tostring(v)
    end
end

function key_to_str(k)
    if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
        return k
    else
        return "[" .. val_to_str(k) .. "]"
    end
end

function Picasa.tableToString(tbl)
    local result, done = {}, {}
    for k, v in ipairs(tbl) do
        table.insert(result, val_to_str(v))
        done[k] = true
    end
    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(result, key_to_str(k) .. "=" .. val_to_str(v))
        end
    end
    return "{" .. table.concat(result, ",") .. "}"
end

--- Scans and loads image edits from a Picasa.ini file.
-- The given directory is indexed within the Picasa namespace, where the value is the path
-- of the Picasa.ini file. This allows one to avoid to scan one Picasa.ini file multiple times.
-- All edits are indexed within the Picasa namespace, where the key is given by the image file name
-- and the value are a table of edits and its parameters.
-- @param picasaIniDirPath Directory to search Picasa.ini file.
-- @return Path of the Picasa.ini file found or nil if the file was not found in the directory.
function Picasa.loadIniFile(picasaIniDirPath)
    local picasaIniFilePath = Picasa.childPath(picasaIniDirPath, 'Picasa.ini')
    local file = io.open(picasaIniFilePath)
    if file == nil then
        picasaIniFilePath = Picasa.childPath(picasaIniDirPath, '.picasa.ini')
        file = io.open(picasaIniFilePath)
        if file == nil then
            Picasa[picasaIniDirPath] = false
            log(Picasa.INFO, "Directory without Picasa file: " .. picasaIniDirPath)
            return nil
        end
    end
    Picasa[picasaIniDirPath] = picasaIniFilePath
    log(Picasa.INFO, "Directory with Picasa file: " .. picasaIniFilePath)


    local currentLine = file:read()
    local currentLineNumber = 1

    --- Advance to next line.
    local function nextLine()
        currentLine = file:read()
        currentLineNumber = currentLineNumber + 1
        return currentLine
    end

    --- Helper method to log about the current line.
    -- @param level Log level (INFO, DEBUG, ...)
    -- @param message Log messagem. It may contain placeholders for string.format().
    -- @param ... Extra params for string.format().
    local function lineLog(level, message, ...)
        if arg == nil then
            Picasa.logBridge(level, message, currentLineNumber)
        else
            Picasa.logBridge(level, string.format(message, unpack(arg)), currentLineNumber)
        end
    end

    --- Skip the current line if it is empty (white spaces and tabs count as empty).
    -- @return true if the line was skipped, false otherwise
    local function skipEmptyLine()
        if currentLine:find('^%s*$') == nil then
            -- Current line does not is not empty.
            return false
        end
        lineLog(Picasa.DEBUG, "Skip empty line.")
        nextLine()
        return true
    end

    --- Skip the current line if it contains only a comment.
    -- @return true if the line was skipped, false otherwise
    local function skipComments()
        if currentLine:find('^%s*#') == nil then
            -- Current line does not contain a comment
            return false
        end
        lineLog(Picasa.DEBUG, "Skip comment.")
        nextLine()
        return true
    end

    --- Skip the line if it contains a property.
    -- @return true if the line was skipped, false otherwise
    local function skipProperty()
        local name = currentLine:match('^%s*([%w_]+)=')
        if name == nil then
            -- Current line does not contain a property
            return false
        end
        lineLog(Picasa.DEBUG, "Skip property '%s'.", name)
        nextLine()
        return true
    end

    --- Skip lines that belong of a section that starts at the current line.
    -- @return true if the section was skipped, false otherwise
    local function skipSection()
        local sectionName = currentLine:match('^%s*%[(.*)%]%s*$')
        if sectionName == nil then
            -- Current line is not a section header.
            return false
        end

        lineLog(Picasa.DEBUG, "Ignore section '%s'.", sectionName)
        nextLine()
        while currentLine ~= nil do
            if not (skipEmptyLine()
                    or skipComments()
                    or skipProperty()) then
                break
            end
        end
        return true
    end

    --- Read lines that belong of a section that starts at the current line and that describe image edits.
    -- @return true if the section was read, false otherwise
    local function handleImageSection()
        local imageFileName = currentLine:match('^%s*%[(.*)%]%s*$')
        if imageFileName == nil then
            -- Current line is not a section header.
            return false
        end

        -- File name with extension
        local findResult = imageFileName:find('%.')
        if findResult == nil then
            -- Header name does not contain a dot for the file extension (probably not a file name for an image).
            return false
        end

        lineLog(Picasa.DEBUG, "Handle image %s.", imageFileName)
        nextLine()

        -- Index all edits for the image within the Picasa namespace.
        local imageInfo = {}
        Picasa[Picasa.childPath(picasaIniDirPath, imageFileName)] = imageInfo

        --- Read the line if it contains an implemented edit property.
        -- @return true if the line was read, false otherwise
        local function readProperty()
            local propertyName, propertyValue = currentLine:match('^%s*([%w_]+)=(.*)$')
            if propertyName == nil then
                -- Current line does not contain a property
                return false
            end
            local uppercasePropertyName = propertyName:upper()
            if uppercasePropertyName == 'STAR' and propertyValue:upper() == 'YES' then
                imageInfo.star = true
                lineLog(Picasa.DEBUG, "Set star.")
                nextLine()
                return true
            elseif uppercasePropertyName == 'CAPTION' then
                imageInfo.caption = propertyValue
                lineLog(Picasa.DEBUG, "Set caption to '%s'.", imageInfo.caption)
                nextLine()
                return true
            elseif uppercasePropertyName == 'ROTATE' then
                local rotate = propertyValue:match('rotate%((%d+)%)')
                if (rotate == nil) then
                    lineLog(Picasa.DEBUG, "Invalid rotate attribute.")
                else
                    imageInfo.rotate = rotate
                    lineLog(Picasa.DEBUG, "Set rotate to %d.", imageInfo.rotate)
                end
                nextLine()
                return true
            elseif uppercasePropertyName == 'KEYWORDS' then
                imageInfo.keywords = split(propertyValue, ',')
                lineLog(Picasa.DEBUG, "Set keywords to '%s'", imageInfo.keywords)
                nextLine()
                return true
            elseif uppercasePropertyName == 'FILTERS' then
                -- The filter property has a value that is a list of pairs name=1[,param1,param2...];
                -- The first value is always 1. Following values are parameters, that depend on the filter.

                for fieldName, fieldValuesStr in propertyValue:gmatch("([%w_]+)=([^;]+)") do
                    local fieldValues = split(fieldValuesStr, ',')
                    if (#fieldValues < 1) or fieldValues[1] ~= '1' then
                        lineLog(Picasa.WARN, "Invalid filter parameters '%s'.", fieldName)
                    else
                        if fieldName == 'enhance' then
                            imageInfo.enhance = true
                            lineLog(Picasa.DEBUG, "Set enhance filter.")
                        elseif fieldName == 'autolight' then
                            imageInfo.autolight = true
                            lineLog(Picasa.DEBUG, "Set autolight filter.")
                        elseif fieldName == 'autocolor' then
                            imageInfo.autocolor = true
                            lineLog(Picasa.DEBUG, "Set autocolor filter.")
                        elseif fieldName == 'bw' then
                            imageInfo.blackWhite = true
                            lineLog(Picasa.DEBUG, "Set black & white filter.")
                        elseif fieldName == 'tilt' then
                            if (#fieldValues == 3) then
                                imageInfo.angle = tonumber(fieldValues[2])
                                imageInfo.scale = tonumber(fieldValues[3])
                            end
                            if imageInfo.angle ~= nil and imageInfo.scale ~= nil then
                                lineLog(Picasa.DEBUG, "Set tilt to %f.", imageInfo.angle)
                                lineLog(Picasa.DEBUG, "Set scale to %f.", imageInfo.scale)
                            else
                                lineLog(Picasa.WARN, "Invalid filter parameters '%s'.", fieldName)
                            end
                        elseif fieldName == 'crop64' then
                            local hexLeft, hexTop, hexRight, hexBottom = fieldValues[2]:match('(%w+%w+%w+%w+)(%w+%w+%w+%w+)(%w+%w+%w+%w+)(%w+%w+%w+%w+)')
                            if hexLeft ~= nil and hexTop ~= nil and hexRight ~= nil and hexBottom ~= nil then
                                imageInfo.crop = {
                                    left = tonumber(hexLeft, 16) / 65536,
                                    top = tonumber(hexTop, 16) / 65536,
                                    right = tonumber(hexRight, 16) / 65536,
                                    bottom = tonumber(hexBottom, 16) / 65536
                                }
                            end
                            if imageInfo.crop ~= nil and imageInfo.crop.left ~= nil and imageInfo.crop.top ~= nil and imageInfo.crop.right ~= nil and imageInfo.crop.bottom ~= nil then
                                lineLog(Picasa.DEBUG, "Set crop to %g, %g, %g, %g.", imageInfo.crop.left, imageInfo.crop.top, imageInfo.crop.right, imageInfo.crop.bottom)
                            else
                                lineLog(Picasa.WARN, "Invalid filter parameters '%s'.", fieldName)
                            end
                        else
                            lineLog(Picasa.DEBUG, "Ignore filter '%s'.", fieldName)
                        end
                    end
                end

                nextLine()
                return true
            else
                lineLog(Picasa.DEBUG, "Ignore property '%s'.", propertyName)
                nextLine()
                return true
            end
        end

        while currentLine ~= nil do
            local ok = skipEmptyLine() or skipComments() or readProperty()
            if (not ok) then break
            end
        end
        lineLog(Picasa.INFO, "Imported image %s with edits %s.", imageFileName, Picasa.tableToString(imageInfo))
        return true
    end

    while currentLine ~= nil do
        local ok = skipEmptyLine() or skipComments() or handleImageSection() or skipSection()
        if (not ok) then break
        end
    end

    io.close(file)

    return picasaIniFilePath
end

return Picasa