type
    Lump = object
        name: string
        off, size: uint32

type
    Thing = object
        ednum: uint32

type
    Sidedef = object
        texturetop: string
        texturebottom: string
        texturemiddle: string

type
    Sector = object
        texturefloor: string
        textureceiling: string

type
    MapObj = tuple
        mapname: string
        things: seq[Thing]
        sidedefs: seq[Sidedef]
        sectors: seq[Sector]