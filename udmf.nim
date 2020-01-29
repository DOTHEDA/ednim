type 
    UDMFVar = object
        variable: string
        value: string

type
    UDMFObj = object
        name: string
        values: seq[UDMFVar]

type
    UDMFStuff = tuple
        things: seq[Thing]
        sidedefs: seq[Sidedef]
        sectors: seq[Sector]

proc parseUDMF(buffer: seq[byte], lump: Lump): UDMFStuff =
    var variables: seq[UDMFObj]
    var tmpVars: seq[UDMFVar]
    
    var isComment: uint8 = 0
    var lastScopeName: string
    var scopeString: string
    var scope: uint32 = 0
    for c in buffer[lump.off ..< lump.off + lump.size]:
        let ch = cast[char](c)

        # wtf?
        # 0 is not a comment, 1 is a suspected comment,
        # 2 is a comment, 3 is a suspected multiline comment,
        # 4 is a multiline comment
        if isComment == 2 and ch == '\n':
            isComment = 0
        elif isComment == 4 and ch == '/':
            isComment = 0
        elif isComment == 3 and ch == '*':
            isComment = 4
        elif isComment == 1 and ch != '/':
            isComment = 0
        elif isComment == 1 and ch == '/':
            isComment = 2
        elif isComment == 1 and ch == '*':
            isComment = 3
        elif isComment == 0 and ch == '/':
            isComment = 1
        
        if not (isComment == 1 or isComment == 3) and
        not (ch == '/' or ch == '*') and
        not (isComment == 2 or isComment == 4):
            if scope == 1 and ch != '}':
                scopeString.add(ch)
            if scope == 0 and
            not (ch == ' ' or ch == '\t' or ch == '\n' or ch == '{'):
                lastScopeName.add(ch)


            if ch == '{':
                scope.inc
            elif ch == '}':
                if scope.pred == 0:
                    for ln in scopeString.split(';'):
                        if ln.split('=').len > 1:
                            let getVar =  ln.replace("\n", "")
                                            .split('=')[0]
                                            .strip()
                            let getVal =  ln.replace("\n", "")
                                            .split('=')[1]
                                            .strip()
                                            .replace("\"", "")

                            tmpVars.add(UDMFVar(variable: getVar, value: getVal))
                    variables.add(UDMFObj(  name: lastScopeName.replace("\c", ""),
                                            values: tmpVars))
                    scopeString = ""
                    lastScopeName = ""
                    system.reset(tmpVars)


                scope.dec

    var tmpSidedefs: seq[Sidedef]
    var tmpThings: seq[Thing]
    var tmpSectors: seq[Sector]
    for v in variables:
        if v.name == "thing":
            var tmpObj: Thing
            for t in v.values:
                if t.variable == "type":
                    tmpObj.ednum = cast[uint32](t.value.parseUInt)
            tmpThings.add(tmpObj)
        elif v.name == "sidedef":
            var tmpObj: Sidedef
            for s in v.values:
                if s.variable == "texturetop":
                    tmpObj.texturetop = s.value
                if s.variable == "texturebottom":
                    tmpObj.texturebottom = s.value
                if s.variable == "texturemiddle":
                    tmpObj.texturemiddle = s.value
            tmpSidedefs.add(tmpObj)
        elif v.name == "sector":
            var tmpObj: Sector
            for s in v.values:
                if s.variable == "texturefloor":
                    tmpObj.texturefloor = s.value
                if s.variable == "textureceiling":
                    tmpObj.textureceiling = s.value
            tmpSectors.add(tmpObj)
    
    result.things = tmpThings
    result.sidedefs = tmpSidedefs
    result.sectors = tmpSectors
    

