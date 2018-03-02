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
function string:split(sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields + 1] = c end)
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

function Picasa.loadIniFile(picasaIniFilePath)
    local picasaIniDirPath = Picasa.directoryPath(picasaIniFilePath)
    local file = io.open(picasaIniFilePath)
    if file == nil then
        error("Picasa file does not exist.")
    end

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

        lineLog(Picasa.INFO, "Handle image %s.", imageFileName)
        nextLine()

        -- Index all edits for the image.
        local imageInfo = {}
        Picasa[Picasa.childPath(picasaIniDirPath, imageFileName)] = imageInfo

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
                local rotate = propertyValue:match('rotate%((%d+))%)')
                if (rotate == nil) then
                    lineLog(Picasa.DEBUG, "Invalid rotate attribute.")
                else
                    imageInfo.rotate = rotate
                    lineLog(Picasa.DEBUG, "Set rotate to %d.", imageInfo.rotate)
                end
                nextLine()
                return true
            elseif uppercasePropertyName == 'KEYWORDS' then
                imageInfo.keywords = propertyValue:split(',')
                lineLog(Picasa.DEBUG, "Set keywords to '%s'", imageInfo.keywords)
                nextLine()
                return true
            elseif uppercasePropertyName == 'FILTERS' then
                local fields = {}
                propertyValue:gsub('([%w_]+)=([^;]+)', function(n, v)
                    fields[n] = v:split(',')
                end)
                for fieldName, fieldValues in pairs(fields) do
                    if fieldName == 'enhance' and fieldValues[1] == '1' then
                        imageInfo.enhance = true
                        lineLog(Picasa.DEBUG, "Set enhance filter.")
                    elseif fieldName == 'autolight' and fieldValues[1] == '1' then
                        imageInfo.autolight = true
                        lineLog(Picasa.DEBUG, "Set autolight filter.")
                    elseif fieldName == 'autocolor' and fieldValues[1] == '1' then
                        imageInfo.autocolor = true
                        lineLog(Picasa.DEBUG, "Set autocolor filter.")
                    elseif fieldName == 'bw' and fieldValues[1] == '1' then
                        imageInfo.blackWhite = true
                        lineLog(Picasa.DEBUG, "Set black & white filter.")
                    elseif fieldName == 'tilt' and fieldValues[1] == '1' then
                        imageInfo.angle = tonumber(fieldValues[2])
                        imageInfo.scale = tonumber(fieldValues[3])
                        lineLog(Picasa.DEBUG, "Set tilt to %f.", imageInfo.angle)
                        lineLog(Picasa.DEBUG, "Set scale to %f.", imageInfo.scale)
                    elseif fieldName == 'crop64' and fieldValues[1] == '1' then
                        local hexLeft, hexTop, hexRight, hexBottom = fieldValues[2]:match('(%w+%w+%w+%w+)(%w+%w+%w+%w+)(%w+%w+%w+%w+)(%w+%w+%w+%w+)')
                        if hexLeft ~= nil and hexTop ~= nil and hexRight ~= nil and hexBottom ~= nil then
                            imageInfo.crop = {
                                left = tonumber(hexLeft, 16) / 65536,
                                top = tonumber(hexTop, 16) / 65536,
                                right = tonumber(hexRight, 16) / 65536,
                                bottom = tonumber(hexBottom, 16) / 65536
                            }
                        else
                            lineLog(Picasa.DEBUG, "Set crop to %f, %f, %f, %f.", imageInfo.crop.left, imageInfo.crop.top, imageInfo.crop.right, imageInfo.bottom)
                        end
                    else
                        lineLog(Picasa.DEBUG, "Ignore filter '%s'.", fieldName)
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
        return true
    end

    while currentLine ~= nil do
        local ok = skipEmptyLine() or skipComments() or handleImageSection() or skipSection()
        if (not ok) then break
        end
    end

    io.close(file)
end

return Picasa