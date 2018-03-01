--
-- Created by IntelliJ IDEA.
-- User: x7ws
-- Date: 01/03/2018
-- Time: 10:25
-- To change this template use File | Settings | File Templates.
--
local Picasa = {}

function string:split(sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end


local function decodeRotate(value)
    local rotate = value:match('rotate%((%d+))%)')
    return rotate
end

function Picasa.loadIniFile(picasaIniDirPath, picasaIniFilePath)
    local file = io.open(picasaIniFilePath)
    if file == nil then
        debug("File not found")
        return
    end
    local line = file:read()
    local lineNumber = 1

    local function debug(message, ...)
        if arg == nil then
            print(lineNumber, message)
        else
            print(lineNumber, string.format(message, unpack(arg)))
        end
    end

    local function nextLine()
        line = file:read()
        lineNumber = lineNumber + 1
        return line
    end

    local function skipEmptyLine()
        if line:find('^%s*$') ~= nil then
            debug("Skip empty line.")
            nextLine()
            return true
        end
        return false
    end

    local function skipComments()
        if line:find('^%s*#') ~= nil then
            debug("Skip comment.")
            nextLine()
            return true
        end
        return false
    end

    local function skipProperty()
        local name = line:match('^%s*([%w_]+)=')
        if name ~= nil then
            debug("Skip property '%s'.", name)
            nextLine()
            return true
        end
        return false
    end

    local function handleHeader()
        local sectionName = line:match('^%s*%[(.*)%]%s*$')
        if sectionName == nil then
            return false
        end

        local findResult = string.find(sectionName, '%.')
        if findResult == nil then
            debug("Handle section %s.", sectionName)
            nextLine()
            while line ~= nil do
                local ok = skipEmptyLine() or skipComments() or skipProperty()
                if (not ok) then break end
            end
            return true
        else
            debug("Handle image %s.", sectionName)
            nextLine()
            local imageInfo = {}
            Picasa[picasaIniDirPath..'/'..sectionName] = imageInfo
            local function readProperty()
                local name, value = line:match('^%s*([%w_]+)=(.*)$')
                if name == nil then
                    return false
                end
                local upperCaseName = name:upper()
                if upperCaseName == 'STAR' then
                    local hasStar = value:upper() == 'YES'
                    debug("Set star %s.", tostring(hasStar))
                    imageInfo.star = hasStar
                    nextLine()
                    return true
                elseif upperCaseName == 'CAPTION' then
                    debug("Set caption.")
                    imageInfo.caption = value
                    nextLine()
                    return true
                elseif upperCaseName == 'KEYWORDS' then
                    debug("Set keywords.")
                    imageInfo.keywords = value:split(',')
                    nextLine()
                    return true
                elseif upperCaseName == 'FILTERS' then
                    local fields = {}
                    value:gsub('([%w_]+)=([^;]+)', function(n, v)
                        fields[n] = v:split(',')
                    end)
                    for fieldName, fieldValues in pairs(fields) do
                        if fieldName == 'enhance' then
                            imageInfo.enhance = fieldValues[1] == '1'
                        elseif fieldName == 'autolight' then
                            imageInfo.autolight = fieldValues[1] == '1'
                        elseif fieldName == 'autocolor' then
                            imageInfo.autocolor = fieldValues[1] == '1'
                        elseif fieldName == 'bw' then
                            imageInfo.blackWhite = fieldValues[1] == '1'
                        elseif fieldName == 'tilt' then
                            if fieldValues[1] == '1' then
                                imageInfo.angle = tonumber(fieldValues[2])
                                imageInfo.scale = tonumber(fieldValues[3])
                            end
                        elseif fieldName == 'crop64' then
                            if fieldValues[1] == '1' then
                                local hexLeft, hexTop, hexRight, hexBottom = fieldValues[2]:match('(%w+%w+%w+%w+)(%w+%w+%w+%w+)(%w+%w+%w+%w+)(%w+%w+%w+%w+)')
                                if hexLeft ~= nil and hexTop ~= nil and hexRight ~= nil and hexBottom ~= nil then
                                    imageInfo.crop = {
                                        left = tonumber(hexLeft, 16) / 65536,
                                        top = tonumber(hexTop, 16) / 65536,
                                        right = tonumber(hexRight, 16) / 65536,
                                        bottom = tonumber(hexBottom, 16) / 65536
                                    }
                                end
                            end
                        end
                    end

                    nextLine()
                    return true
                else
                    debug(" - Ignore property '%s'.", name)
                    nextLine()
                    return true
                end
            end

            while line ~= nil do
                local ok = skipEmptyLine() or skipComments() or readProperty()
                if (not ok) then break
                end
            end
            return true
        end
    end

    while line ~= nil do
        local ok = skipEmptyLine() or skipComments() or handleHeader()
        if (not ok) then break
        end
    end

    io.close(file)
end

return Picasa