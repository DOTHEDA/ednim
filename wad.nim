proc getWadData(fname: string): seq[byte] =
    var b: byte
    var buff: seq[byte]
    var stream = newFileStream(fname, fmRead)
    if not isNil(stream):
        while stream.readData(b.addr, 1) != 0:
            buff.add(b)
    stream.close()
    result = buff
    

proc getLumps(buffer: seq[byte]): seq[Lump] =
    let numlumps = bytesToInt(buffer[4..<8])
    let infotable = bytesToInt(buffer[8..<12])

    var lumps: seq[Lump]

    for i in countup(0'u32, numlumps - 1):
        let off = infotable + i * 16
        var name: string = bytesToString(buffer[off + 8 ..< off + 16])
        var lumpObj: Lump
        lumpObj.name = name
        lumpObj.off = bytesToInt(buffer[off ..< off + 4])
        lumpObj.size = bytesToInt(buffer[off + 4 ..< off + 8])

        lumps.add(lumpObj)

    result = lumps

proc getMapData(buffer: seq[byte], lumps: seq[Lump]): seq[MapObj] =
    var isMap: bool = false
    var outSeq: seq[MapObj]
    var tempMap: MapObj
    for l in lumps:

        if isMap and l.name.toUpperAscii() == "THINGS":
            let tLump: seq[byte] = buffer[l.off..<l.off+l.size]

            # get the things lump type (doom or hexen format)
            let tType: uint32 = if l.size mod 10 == 0:
                                    10'u32
                                elif l.size mod 20 == 0:
                                    20'u32
                                else:
                                    0'u32

            # check to see if the things lump is valid or not
            if tType == 0'u32:
                echo "THINGS lump invalid"
                continue

            # get the ednums
            for i in countup(0'u32, cast[uint32](tLump.len) div tType):
                let tNum = Thing(ednum: bytesToInt(buffer[l.off+i*tType+6..<l.off+i*tType+8]))
                tempMap.things.add(tNum)

        if isMap and l.name.toUpperAscii() == "SIDEDEFS":

            if l.size mod 30'u32 != 0:
                echo "SIDEDEFS lump invalid"
                continue

            for i in countup(0'u32, l.size div 30'u32):
                let upperTex: string = bytesToString(buffer[l.off+i*30+4..<l.off+i*30+12])
                let lowerTex: string = bytesToString(buffer[l.off+i*30+12..<l.off+i*30+20])
                let midTex: string = bytesToString(buffer[l.off+i*30+20..<l.off+i*30+28])

                let sdef = Sidedef( texturetop: upperTex,
                                    texturebottom: lowerTex,
                                    texturemiddle: midTex )
                tempMap.sidedefs.add(sdef)

        if isMap and l.name.toUpperAscii() == "SECTORS":

            if l.size mod 26'u32 != 0:
                echo "SECTORS lump invalid"
                continue
            
            for i in countup(0'u32, l.size div 26'u32):
                let floorTex: string = bytesToString(buffer[l.off+i*26+4..<l.off+i*26+12])
                let ceilTex: string = bytesToString(buffer[l.off+i*26+12..<l.off+i*26+20])

                let sec = Sector(   texturefloor: floorTex,
                                    textureceiling: ceilTex )
                
                tempMap.sectors.add(sec)

        if isMap and l.name.toUpperAscii() == "TEXTMAP":
            for x in buffer.parseUDMF(l).things:
                tempMap.things.add(x)
            for x in buffer.parseUDMF(l).sidedefs:
                tempMap.sidedefs.add(x)
            for x in buffer.parseUDMF(l).sectors:
                tempMap.sectors.add(x)

        if re.match(l.name, re"MAP\d\d") or re.match(l.name, re"E\dM\d"):
            isMap = true
            tempMap.mapname = l.name
        
        if isMap and (l.name.toUpperAscii() == "BLOCKMAP" or l.name.toUpperAscii() == "ENDMAP"):
            isMap = false
            outSeq.add(tempMap)
            system.reset(tempMap)
    result = outSeq
