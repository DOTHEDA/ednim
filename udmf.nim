import strutils
import sequtils
import sets

type
    Textmap = ref object of RootObj
        mapName: string
        comment: string
        texture: string

    Thing = ref object of Textmap
        id: int32
        x: float32
        y: float32
        ednum: int32
        angle: int32
        dm: bool
        coop: bool

    Vertex = ref object of Textmap
        x: float32
        y: float32

    Linedef = ref object of Textmap
        v1: int32
        v2: int32
        front: int32
        back: int32
        twoSided: bool



    Sidedef = ref object of Textmap
        sector: int32
        textureBottom: string
        textureMiddle: string
        textureTop: string
        offsetX: int32
        offsetY: int32

    Sector = ref object of Textmap
        textureFloor: string
        textureCeiling: string
        heightFloor: int32
        heightCeiling: int32
        lightLevel: int32

type
    TextmapLump = tuple
        mapName: string
        data: string

proc getTextmaps(wad: seq[char], lumps: seq[Lump]): seq[TextmapLump] =
    var textMaps: seq[TextmapLump]
    for i in 0 ..< lumps.len():
        if checkIfMap(lumps[i]):
            if lumps[i+1].name.toUpper() == "TEXTMAP":
                var outString: string
                for c in wad[lumps[i+1].offset ..< lumps[i+1].size + lumps[i+1].offset]:
                    outString.add(c)
                textMaps.add((mapName: lumps[i].name, data: outString))

    result = textMaps


proc parseTextmaps(lump: TextmapLump, areTextures: bool = false): seq[Textmap] =

    var thingCount: uint32 = 0
    var thingEdnums: seq[int32]

    var textureCount: uint32 = 0
    var textures: seq[string]

    var startDef: bool
    var bracketNest: uint8 = 0
    var nestedString: string
    var varType: string

    for i, c in lump.data:

        if c == 't' and
        lump.data.len() - i >= 8:

            if startDef == false:
                if lump.data[i ..< i+5] == "thing":
                    startDef = true
                    varType = "thing"

        if c == 's' and
        lump.data.len - i >= 8:
            if startDef == false:
                if lump.data[i ..< i+6] == "sector":
                    startDef = true
                    varType = "sector"
                elif lump.data[i ..< i+7] == "sidedef":
                    startDef = true
                    varType = "sidedef"
            
        if c == '}' and startDef:
            if not areTextures:
                if varType == "thing" and
                nestedString.len() > 0:
                    for l in nestedString.split(';'):
                        let variable = l.split('=')
                        if variable[0].strip() == "type":
                            thingEdnums.add(cast[int32](variable[1].strip().parseInt()))

            else:
                
                if varType == "sidedef" and
                nestedString.len() > 0:
                    for l in nestedString.split(';'):
                        let variable = l.split('=')
                        case variable[0].strip()
                        of "texturetop", "texturemiddle", "texturebottom":
                            textures.add(variable[1].strip())

                if varType == "sector" and
                nestedString.len() > 0:
                    for l in nestedString.split(';'):
                        let variable = l.split('=')
                        case variable[0].strip()
                        of "texturefloor", "textureceiling":
                            textures.add(variable[1].strip())


            if bracketNest.pred() == 0'u8:
                startDef = false
            bracketNest.dec()

            nestedString = ""
            varType = ""

        if startDef and bracketNest > 0'u8:
            nestedString.add(c)
            
        if c == '{' and startDef:
            bracketNest.inc()
            
    
    if not areTextures:
        var outThings = newSeq[Textmap](thingEdnums.deDuplicate().len())
        if thingEdnums.len() > 0:
            for i, j in thingEdnums.deDuplicate():
                new outThings[i]

                outThings[i] = Thing(ednum: j)

        result = outThings
    else:
        var outTextures = newSeq[Textmap](textures.deDuplicate().len())
        if textures.len() > 0:
            for i, j in textures.deDuplicate():
                new outTextures[i]

                outTextures[i] = Textmap(texture: j.strip(true, true, {'"'}))

        result = outTextures