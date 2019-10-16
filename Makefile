WINCC=x86_64-w64-mingw32-gcc
EXEC=ednim

default: 
	nim c --threads:on -o:$(EXEC) main.nim

release:
	nim c --threads:on -o:$(EXEC) -d:release main.nim

run:
	nim c --threads:on -o:$(EXEC) -r main.nim

windows:
	nim c --threads:on -o:$(EXEC).exe \
	-d:release \
	--cpu:amd64 \
    --os:windows \
	--gcc.exe:$(WINCC) --gcc.linkerexe:$(WINCC) \
    main.nim