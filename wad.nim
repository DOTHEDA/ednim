import strutils
import macros

type
    WADHeader = object
        id: string
        numLumps: uint32
        tablesOffset: uint32

type
    Lump = tuple
        name: string
        offset: uint32
        size: uint32

#gets the WAD header so it can be checked as a valid WAD
proc getID(wad: seq[char]): string =
    let id: seq[char] = wad[0..3]
    var idString: string
    for c in id: idString.add(c)
    result = idString

#gets all lumps
proc getLumps(wad: seq[char]): seq[Lump] =
    let header = WADHeader( id: getID(wad),
                            numLumps: getInt(wad[4..7]),
                            tablesOffset: getInt(wad[8..11]))

    var lumps = newSeq[Lump](header.numLumps)

    for i in 0 ..< header.numLumps:
        var outString: string
        let t = header.tablesOffset
        for c in wad[i * 16 + t + 8 ..< i * 16 + t + 16]:
            if c != '\x00': outString.add(c)
        
        lumps[i].name = outString
        lumps[i].offset = wad[i * 16 + t ..< i * 16 + t + 4].getInt()
        lumps[i].size = wad[i * 16 + t + 4 ..< i * 16 + t + 8].getInt() 

    
    result = lumps

proc checkIfMap(lump: Lump): bool =
    if lump.name.len() >= 4:
        if lump.name[0..2] == "MAP" and
        lump.name[3..4].parseInt() is int:
            result = true
        elif lump.name[0] == 'E' and
        lump.name[2] == 'M' and
        lump.name[1..1].parseInt() is int and
        lump.name[3..3].parseInt() is int:
            result = true
        else:
            result = false

