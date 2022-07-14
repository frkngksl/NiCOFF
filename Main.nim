import winim/lean
import ptr_math
import std/streams
import std/strutils
import os
import Structs


proc PrintBanner():void = 
    var banner = """
 ______  _  ______ _____  _______ _______ 
|  ___ \(_)/ _____) ___ \(_______|_______)
| |   | |_| /    | |   | |_____   _____   
| |   | | | |    | |   | |  ___) |  ___)  
| |   | | | \____| |___| | |     | |      
|_|   |_|_|\______)_____/|_|     |_|      
                
                @R0h1rr1m                                       
"""
    echo banner

proc DisplayHelp():void = 
    echo "[!] Usage: ",getAppFilename()," <Object File Path> <optional arguments>"

proc ReadFileFromDisk(filePath:string):seq[byte] = 
    var strm = newFileStream(filePath, fmRead)
    if(not isNil(strm)):
        var fileBuffer:string = strm.readAll()
        var returnValue:seq[byte] = @(fileBuffer.toOpenArrayByte(0,fileBuffer.high))
        return returnValue
    return @[]

proc HexStringToByteArray(hexString:string,hexLength:int):seq[byte] =
    var returnValue:seq[byte] = @[]
    for i in countup(0,hexLength-1,2):
        try:
            #cho hexString[i..i+1]
            returnValue.add(fromHex[uint8](hexString[i..i+1]))
        except ValueError:
            return @[]
    #fromHex[uint8]
    return returnValue

proc GetNumberOfExternalFunctions(fileBuffer:seq[byte],textSectionHeader:ptr SectionHeader):uint64 =
    var returnValue:uint64=0
    var symbolTableCursor:ptr SymbolTableEntry = nil
    var symbolTable:ptr SymbolTableEntry = cast[ptr SymbolTableEntry](unsafeAddr(fileBuffer[0]) + cast[int]((cast[ptr FileHeader](unsafeAddr(fileBuffer[0]))).PointerToSymbolTable))
    var relocationTableCursor:ptr RelocationTableEntry = cast[ptr RelocationTableEntry](unsafeAddr(fileBuffer[0]) + cast[int](textSectionHeader.PointerToRelocations))
    for i in countup(0,cast[int](textSectionHeader.NumberOfRelocations-1)):
        # echo sizeof(SymbolTableEntry)
        symbolTableCursor = cast[ptr SymbolTableEntry](symbolTable + cast[int](relocationTableCursor.SymbolTableIndex))
        if(symbolTableCursor.StorageClass == IMAGE_SYM_CLASS_EXTERNAL and symbolTableCursor.SectionNumber == 0):
            returnValue+=1
        #relocationTableCursor = cast[ptr RelocationTableEntry](cast[LPVOID](relocationTableCursor)+sizeof(RelocationTableEntry))
        relocationTableCursor+=1
    return returnValue * cast[uint64](sizeof(ptr byte))



proc RunCOFF(functionName:string,fileBuffer:seq[byte],argumentBuffer:seq[byte]):bool = 
    var fileHeader:ptr FileHeader = cast[ptr FileHeader](unsafeAddr(fileBuffer[0]))
    var totalSize:uint64 = 0
    # Some COFF files may have Optional Header to just increase the size according to MSDN
    var sectionHeaderArray:ptr SectionHeader = cast[ptr SectionHeader] (unsafeAddr(fileBuffer[0])+cast[int](fileHeader.SizeOfOptionalHeader)+sizeof(FileHeader))
    var sectionHeaderCursor:ptr SectionHeader = sectionHeaderArray
    var textSectionHeader:ptr SectionHeader = nil
    var sectionInfoList: seq[SectionInfo] = @[]
    var tempSectionInfo:SectionInfo
    var allocatedMemory:LPVOID = nil
    var memoryCursor:uint64 = 0
    var symbolTable:ptr SymbolTableEntry = cast[ptr SymbolTableEntry](unsafeAddr(fileBuffer[0]) + cast[int](fileHeader.PointerToSymbolTable))
    var symbolTableCursor:ptr SymbolTableEntry = nil
    var relocationTableCursor:ptr RelocationTableEntry = nil
    var sectionIndex:int = 0
    var isExternal:bool = false
    var isInternal:bool = false
    var patchAddress:LPVOID = nil
    # Calculate the total size for allocation
    for i in countup(0,cast[int](fileHeader.NumberOfSections-1)):
        #copyMem(sectionAddresses[i],unsafeaddr(fileBuffer[0])+cast[int](sectionHeaderCursor.PointerToRawData),sectionHeaderCursor.SizeOfRawData)
        #echo $(addr(sectionHeaderCursor.Name[0]))
        if($(addr(sectionHeaderCursor.Name[0])) == ".text"):
            textSectionHeader = sectionHeaderCursor
        # Save the section info
        tempSectionInfo.Name = $(addr(sectionHeaderCursor.Name[0]))
        tempSectionInfo.SectionOffset = totalSize
        tempSectionInfo.SectionHeaderPtr = sectionHeaderCursor
        sectionInfoList.add(tempSectionInfo)
        # Add the size
        totalSize+=sectionHeaderCursor.SizeOfRawData
        sectionHeaderCursor+=1
    if(textSectionHeader.isNil()):
        echo "[!] Text section is not found!"
        return false
    # We need to store external function addresses too
    allocatedMemory = VirtualAlloc(NULL, cast[UINT32](totalSize+GetNumberOfExternalFunctions(fileBuffer,textSectionHeader)), MEM_COMMIT or MEM_RESERVE or MEM_TOP_DOWN, PAGE_EXECUTE_READWRITE)
    if(allocatedMemory == NULL):
        echo "[!] Failed for memory allocation!"
        return false
    # Now copy the sections
    sectionHeaderCursor = sectionHeaderArray
    for i in countup(0,cast[int](fileHeader.NumberOfSections-1)):
        copyMem(cast[LPVOID](cast[uint64](allocatedMemory)+memoryCursor),unsafeaddr(fileBuffer[0])+cast[int](sectionHeaderCursor.PointerToRawData),sectionHeaderCursor.SizeOfRawData)
        sectionHeaderCursor+=1
        memoryCursor+=sectionHeaderCursor.SizeOfRawData
    echo "[+] Sections are copied!"
    # Relocations start
    for i in countup(0,cast[int](fileHeader.NumberOfSections-1)):
        echo "  [+] Relocations for section: ",sectionInfoList[i].Name
        relocationTableCursor = cast[ptr RelocationTableEntry](unsafeAddr(fileBuffer[0]) + cast[int](sectionInfoList[i].SectionHeaderPtr.PointerToRelocations))
        for relocationCount in countup(0, cast[int](sectionInfoList[i].SectionHeaderPtr.NumberOfRelocations)):
            symbolTableCursor = symbolTable + cast[int](relocationTableCursor.SymbolTableIndex)
            sectionIndex = cast[int](symbolTableCursor.SectionNumber - 1)
            isExternal = (symbolTableCursor.StorageClass == IMAGE_SYM_CLASS_EXTERNAL and symbolTableCursor.SectionNumber == 0)
            isInternal = (symbolTableCursor.StorageClass == IMAGE_SYM_CLASS_EXTERNAL and symbolTableCursor.SectionNumber != 0)
            patchAddress = cast[LPVOID](cast[uint64](allocatedMemory) + sectionInfoList[i].SectionOffset + cast[uint64](relocationTableCursor.VirtualAddress - sectionInfoList[i].SectionHeaderPtr.VirtualAddress))
            relocationTableCursor+=1
    

    return true

when isMainModule:
    PrintBanner()
    if(paramCount() < 1 or paramCount() > 2):
        DisplayHelp()
        quit(0)
    var fileBuffer:seq[byte] = ReadFileFromDisk(paramStr(1))
    var argumentBuffer:seq[byte] = @[]
    if(fileBuffer.len == 0):
        echo "[!] Error on file read! [",paramStr(1),"]"
        quit(0)
    echo "[+] File is read!"
    if(paramCount() == 2):
        argumentBuffer = HexStringToByteArray(paramStr(2),paramStr(2).len)
        if(argumentBuffer.len == 0):
            echo "[!] Error on unhexlifying the argument!"
            quit(0)
        echo "[+] Argument is unhexlified!"
    if(not RunCOFF("go",fileBuffer,argumentBuffer)):
        echo "[!] Error on executing file!"


    

        
    