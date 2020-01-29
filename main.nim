import sequtils, re, strutils, math, streams, os

proc bytesToInt(a: seq[byte]): uint32 =
    var outp: uint32
    for i in countup(0, a.len - 1):
        outp += (cast[uint32](a[i])) shl (i * 8)
    result = outp

proc bytesToString(a: seq[byte]): string =
    var str: string
    for c in a:
        if cast[char](c) != '\0': str.add(cast[char](c))
    result = str

include "defs.nim"
include "udmf.nim"
include "wad.nim"

let args = (proc: seq[string] =
                for i in countup(0, paramCount()):
                    result.add(paramStr(i)))()

let inWAD = args[args.len - 1]
let buff = getWadData(inWAD)
let lumps = buff.getLumps()
let mapObjects = buff.getMapData(lumps)

let thingSearch =   (proc: uint32 =
                        var sFound = false
                        for a in args:
                            if sFound:
                                sFound = false
                                result = cast[uint32](a.parseUInt)
                            if a == "-e":
                                sFound = true)()
let textureSearch =   (proc: string =
                        var sFound = false
                        for a in args:
                            if sFound:
                                sFound = false
                                result = a
                            if a == "-t":
                                sFound = true)()
for m in mapObjects:
    if thingSearch != 0:
        for t in m.things:
            if t.ednum == thingSearch:
                echo "----\n", m.mapname, "\n----"
                echo t.ednum
                break
    if textureSearch != "":
        var textureFound: string
        for t in m.sidedefs:
            if t.texturetop == textureSearch:
                textureFound = t.texturetop
                break
            elif t.texturebottom == textureSearch:
                textureFound = t.texturebottom
                break
            elif t.texturemiddle == textureSearch:
                textureFound = t.texturemiddle
                break
        for t in m.sectors:
            if t.texturefloor == textureSearch:
                textureFound = t.texturefloor
                break
            elif t.textureceiling == textureSearch:
                textureFound = t.textureceiling
                break
        if textureFound != "":
            echo "---\n", m.mapname, "\n----"
            echo textureFound