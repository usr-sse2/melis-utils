all: bin/awimage bin/add_checksum bin/minfs bin/localidiff

.PHONY: clean

bin:
	mkdir bin

bin/awimage: bin awutils/awimage
	cp awutils/awimage bin

awutils/awimage:
	$(MAKE) -C awutils awimage

bin/add_checksum: bin awutils/add_checksum
	cp awutils/add_checksum bin

awutils/add_checksum:
	$(MAKE) -C awutils add_checksum

bin/minfs: bin lindenis-v833-RTOS-melis-4.0/source/utility/host-tool/minfs_tool/minfs
	cp lindenis-v833-RTOS-melis-4.0/source/utility/host-tool/minfs_tool/minfs bin

bin/localidiff: bin Localidiff/Localidiff.csproj Localidiff/Program.cs
	dotnet publish -c Release Localidiff/Localidiff.csproj -o bin

lindenis-v833-RTOS-melis-4.0/source/utility/host-tool/minfs_tool/minfs:
	$(MAKE) -C lindenis-v833-RTOS-melis-4.0/source/utility/host-tool/minfs_tool


clean:
	rm -Rf bin
	$(MAKE) -C awutils clean
	$(MAKE) -C lindenis-v833-RTOS-melis-4.0/source/utility/host-tool/minfs_tool clean
