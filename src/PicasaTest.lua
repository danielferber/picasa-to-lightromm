--
-- Created by IntelliJ IDEA.
-- User: x7ws
-- Date: 01/03/2018
-- Time: 10:40
-- To change this template use File | Settings | File Templates.
--

Picasa = require "src/Picasa"

function Picasa.logInfoBridge(message, lineNumber)
    if (lineNumber == nil) then
        print(message)
    else
        print(lineNumber, message)
    end
end

function Picasa.logDebugBridge(message, lineNumber)
    if (lineNumber == nil) then
        print(message)
    else
        print(lineNumber, message)
    end
end

function Picasa.logDebugBridge(message, lineNumber)
    if (lineNumber == nil) then
        print(message)
    else
        print(lineNumber, message)
    end
end

Picasa.loadIniFile("/", "inis/2005/2005-10 - Buenos Aires/Picasa.ini")