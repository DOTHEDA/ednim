import strutils
import sequtils
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

type
    THINGS = object
        ednum: uint32

    SECTORS = object
        flatCeiling: string
        flatFloor: string

    SIDEDEFS = object
        textureUpper: string
        textureMiddle: string
        textureLower: string


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

proc getThingsFromMap(  wad: seq[char],
                        lumps: seq[Lump],
                        lumpToGet: string): seq[(string, seq[THINGS])] =
    var outSeq: seq[(string, seq[THINGS])]
    var isMap: bool
    var lastMap: string = ""
    for i in 0 ..< lumps.len():
        if checkIfMap(lumps[i]):
            isMap = true
            lastMap = lumps[i].name
        
        if isMap and
        lumpToGet == "THINGS" and
        lumps[i].name.toUpper() == "THINGS":
            var lumpEdnums: THINGS

            #10 = doom, 20 = hexen
            var thingMapType: uint8 = 0

        
            if lumps[i].size.mod(10'u8) == 0'u8:
                thingMapType = 10
            elif lumps[i].size.mod(20'u8) == 0'u8:
                thingMapType = 20

            var returnEdnums = newSeq[THINGS](cast[int](lumps[i].size div 10))
            for j in 0 ..< lumps[i].size div thingMapType:
                var getEdnum = newSeq[char](4)
                

                getEdnum[0 ..< 2] = wad[j * thingMapType + lumps[i].offset + 6 ..< j * thingMapType + lumps[i].offset + 8]
                getEdnum[2 ..< 4] = ['\x00', '\x00']

                returnEdnums[j] = THINGS(ednum: getEdnum.getInt())
            outSeq.add((lastMap, returnEdnums.deDuplicate()))

        if isMap and
        lumps[i].name.toUpper() == "BLOCKMAP":
            isMap = false
            lastMap = ""
    result = outSeq

proc getTexturesFromMap(  wad: seq[char],
                        lumps: seq[Lump],
                        lumpToGet: string): seq[(string,
                                            seq[SECTORS],
                                            seq[SIDEDEFS])] =
    var outSeq: seq[(string, seq[SECTORS], seq[SIDEDEFS])]
    var isMap: bool
    var lastMap: string = ""
    
    for i in 0 ..< lumps.len():
        var flats: seq[SECTORS]
        var textures: seq[SIDEDEFS]
        if checkIfMap(lumps[i]):
            isMap = true
            lastMap = lumps[i].name
        
        if isMap and
        lumpToGet == "TEXTURES" and
        lumps[i].name.toUpper() == "SECTORS":
            var lumpSectors: SECTORS
            let lumpSize: uint32 = 26

            for j in 0 ..< lumps[i].size div lumpSize:
                let off = lumps[i].offset
                var floorTexture: string
                var ceilingTexture: string
                
                for c in wad[j * lumpSize + off + 4 ..< j * lumpSize + off + 12]:
                    if c != '\x00': floorTexture.add(c)
                for c in wad[j * lumpSize + off + 12 ..< j * lumpSize + off + 20]:
                    if c != '\x00': ceilingTexture.add(c)

                flats.add(SECTORS(flatFloor: floorTexture, flatCeiling: ceilingTexture))
                
            outSeq.add((lastMap, flats.deDuplicate(), textures.deDuplicate()))

        if isMap and
        lumpToGet == "TEXTURES" and
        lumps[i].name.toUpper() == "SIDEDEFS":

            var lumpSidedefs: SIDEDEFS
            let lumpSize: uint32 = 30

            for j in 0 ..< lumps[i].size div lumpSize:
                let off = lumps[i].offset
                var upperTexture: string
                var middleTexture: string
                var lowerTexture: string
                
                for c in wad[j * lumpSize + off + 4 ..< j * lumpSize + off + 12]:
                    if c != '\x00': upperTexture.add(c)
                for c in wad[j * lumpSize + off + 12 ..< j * lumpSize + off + 20]:
                    if c != '\x00': lowerTexture.add(c)
                for c in wad[j * lumpSize + off + 20 ..< j * lumpSize + off + 28]:
                    if c != '\x00': middleTexture.add(c)

                textures.add(SIDEDEFS(textureUpper: upperTexture, textureLower: lowerTexture, textureMiddle: middleTexture))
    
    
            outSeq.add((lastMap, flats.deDuplicate(), textures.deDuplicate()))
        if isMap and
        lumps[i].name.toUpper() == "BLOCKMAP":
            
            isMap = false
            lastMap = ""
        
    result = outSeq