--
-- Created by IntelliJ IDEA.
-- User: x7ws
-- Date: 01/03/2018
-- Time: 10:40
-- To change this template use File | Settings | File Templates.
--

Picasa = require 'src/Picasa'

function Picasa.logBridge(level, message, lineNumber)
    if (lineNumber == nil) then
        print(level, message)
    else
        print(level, lineNumber, message)
    end
end

function Picasa.directoryPath(path)
    pattern1 = "^(.+)/"
    pattern2 = "^(.+)\\"

    if (string.match(path, pattern1) == nil) then
        return path:match(pattern2)
    else
        return path:match(pattern1)
    end
end

function Picasa.childPath(path, child)
    return path..'/'..child
end

Picasa.loadIniFile 'inis/2005/2005-10 - Buenos Aires/'