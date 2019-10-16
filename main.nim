import streams, strutils, sequtils
import os, parseopt

proc getInt(a: seq[char], little: bool = true): uint32 =
    var x: uint32

    if little:
        x = (cast[uint32](a[0]) shl 0) or
            (cast[uint32](a[1]) shl 8) or
            (cast[uint32](a[2]) shl 16) or
            (cast[uint32](a[3]) shl 24)
    else:
        x = (cast[uint32](a[3]) shl 0) or
            (cast[uint32](a[2]) shl 8) or
            (cast[uint32](a[1]) shl 16) or
            (cast[uint32](a[0]) shl 24)

    result = x

include wad
include udmf

proc readEntireFile(file: FileStream): seq[char] =
    
    var fileSize: uint32
    var buff: char

    while file.readData(buff.addr, 1) == 1:
        fileSize = fileSize + 1

    var outSeq = newSeq[char](fileSize)
    
    file.setPosition(0)
    for i in 0 ..< fileSize:
        discard file.readData(buff.addr, 1)
        outSeq[i] = buff

    result = outSeq


proc getEdnums(file: seq[char], areTextures: bool, search: string = ""): string =
    var columns = 4
    var i = 0

    var outString: string

    for m in file.getTextmaps(file.getLumps()):

        let textMapList = m.parseTextmaps(areTextures)
        #TODO: fix the map name being diplayed twice
        echo "-- ", m.mapName, " --"

        for t in textMapList:

            if not areTextures:
                if search == "":
                    outString.add($(t.Thing.ttype))
                    outString.add("\n")

                    i.inc()
                else:
                    if $(t.Thing.ttype) == search:
                        outString.add($(t.Thing.ttype))
                        outString.add("\n")

                        i.inc()
            
            else:
                if search == "":
                    outString.add(t.Textmap.texture)

                    outString.add("\n")

                    i.inc()
                else:
                    if $(t.Textmap.texture).toLower() == search.toLower():
                        outString.add(t.Textmap.texture)
                        outString.add("\n")

                        i.inc()
    
    result = outString




var switchE: bool
var switchO: bool
var switchT: bool
var switchS: string
var switchP: bool

for kind, key, value in getOpt():
    case kind
    of cmdArgument:

        if existsFile(key) and
        key.split('.')[key.split('.').len() - 1].toLower() == "wad":
            if switchE and not switchT:
                var f = newFileStream(key, fmRead)
                var wad = f.readEntireFile()
                f.close()
                let ednums = getEdnums(wad, switchT, switchS)
                if switchS != "":
                    
                    if ednums.len > 0: echo ednums
                    else: echo "no things of that value found"
                else:
                    echo getEdnums(wad, switchT)
            if switchT:
                var f = newFileStream(key, fmRead)
                var wad = f.readEntireFile()
                f.close()

                let ednums = getEdnums(wad, switchT, switchS)
                if ednums.len > 0:
                    if switchS != "":
                        
                        if ednums.len > 0: echo ednums
                        else: echo "no textures with that string found"
                    else:
                        echo getEdnums(wad, switchT)
                else:
                    echo "no textures found in this map (invalid wad/not UDMF?)"
        else:
            echo "file does not exist or is invalid"

    of cmdShortOption, cmdLongOption:
        case key:
        of "e":
            switchE = true
        of "o":
            if value.len() > 0: switchO = true
        of "s":
            if value.len() > 0: switchS = value
        of "t":
            switchT = true
        of "h":
            echo """syntax: [options] [wad file]

-e : lists things

-t : lists textures

-s="name/id" : searches for a specific thing/texture
make sure there are NO SPACES between the = and the option/string


thing search example:
ednim -s=321 -e WADNAME.wad

texture search example (case insensitive):
ednim -s="startan2" -t WADNAME.wad"""
        else:
            echo "incorrect switch"
    of cmdEnd:
        discard
#[

]#