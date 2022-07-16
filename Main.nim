import winim/lean
import ptr_math
import std/streams
import std/strutils
import os
import system
import Structs
import BeaconFunctions

type COFFEntry = proc(args:ptr byte, argssize: uint32) {.stdcall.}


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
    echo "[!] Usage: ",getAppFilename()," <Object File Path> <Function Entry> <optional arguments>"

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
    return returnValue * cast[uint64](sizeof(ptr uint64))

proc GetExternalFunctionAddress(symbolName:string):uint64 =
    var prefixSymbol:string = "__imp_"
    var prefixBeacon:string = "__imp_Beacon"
    var prefixToWideChar:string = "__imp_toWideChar"
    var libraryName:string = ""
    var functionName:string = ""
    var returnAddress:uint64 = 0
    var symbolWithoutPrefix:string = symbolName[6..symbolName.len-1]
    if(not symbolName.startsWith(prefixSymbol)):
        echo "[!] Function with unknown naming convention! [",symbolName,"]"
        return returnAddress
    # Check is it our cs function implementation
    if(symbolName.startsWith(prefixBeacon) or symbolName.startsWith(prefixToWideChar)):
        # TODO implement 23 internal cs function
        for i in countup(0,22):
            if(symbolWithoutPrefix == functionAddresses[i].name):
                return functionAddresses[i].address
    else:
        try:
            # Why removePrefix doesn't work with 2 strings argument?
            var symbolSubstrings:seq[string] = symbolWithoutPrefix.split({'@','$'},2)
            libraryName = symbolSubstrings[0]
            functionName = symbolSubstrings[1]
        except:
            echo "[!] Symbol splitting problem! [",symbolName,"]"
            return returnAddress
        var libraryHandle:HMODULE = LoadLibraryA(addr(libraryName[0]))
        if(libraryHandle != 0):
            returnAddress = cast[uint64](GetProcAddress(libraryHandle,addr(functionName[0])))
            if(returnAddress == 0):
                echo "[!] Error on Function address! [",functionName,"]"
            return returnAddress
        else:
            echo "[!] Error on loading library! [",libraryName,"]"
            return returnAddress
        

proc Read32Le(p:ptr uint8):uint32 = 
    var val1:uint32 = cast[uint32](p[0])
    var val2:uint32 = cast[uint32](p[1])
    var val3:uint32 = cast[uint32](p[2])
    var val4:uint32 = cast[uint32](p[3])
    return (val1 shl 0) or (val2 shl 8) or (val3 shl 16) or (val4 shl 24)

proc Write32Le(dst:ptr uint8,x:uint32):void =
    dst[0] = cast[uint8](x shr 0)
    dst[1] = cast[uint8](x shr 8)
    dst[2] = cast[uint8](x shr 16)
    dst[3] = cast[uint8](x shr 24)

proc Add32(p:ptr uint8, v:uint32) = 
    echo cast[uint64](p)
    Write32le(p,Read32le(p)+v)
    
proc ApplyGeneralRelocations(patchAddress:uint64,sectionStartAddress:uint64,givenType:uint16,symbolOffset:uint32):void =
    var pAddr8:ptr uint8 = cast[ptr uint8](patchAddress)
    var pAddr64:ptr uint64 = cast[ptr uint64](patchAddress)
    var test:uint64 = sectionStartAddress - patchAddress - 4
    echo test
    test+=symbolOffset
    echo test
    echo givenType
    case givenType:
        of IMAGE_REL_AMD64_REL32:
            Add32(pAddr8, cast[uint32](sectionStartAddress + cast[uint64](symbolOffset) -  patchAddress - 4))
            return
        of IMAGE_REL_AMD64_ADDR32NB:
            Add32(pAddr8, cast[uint32](sectionStartAddress - patchAddress - 4))
            return
        of IMAGE_REL_AMD64_ADDR64:
            pAddr64[] = pAddr64[] + sectionStartAddress
            return
        else:
            echo "[!] No code for type: ",givenType

var allocatedMemory:LPVOID = nil

proc RunCOFF(functionName:string,fileBuffer:seq[byte],argumentBuffer:seq[byte]):bool = 
    var fileHeader:ptr FileHeader = cast[ptr FileHeader](unsafeAddr(fileBuffer[0]))
    var totalSize:uint64 = 0
    # Some COFF files may have Optional Header to just increase the size according to MSDN
    var sectionHeaderArray:ptr SectionHeader = cast[ptr SectionHeader] (unsafeAddr(fileBuffer[0])+cast[int](fileHeader.SizeOfOptionalHeader)+sizeof(FileHeader))
    var sectionHeaderCursor:ptr SectionHeader = sectionHeaderArray
    var textSectionHeader:ptr SectionHeader = nil
    var sectionInfoList: seq[SectionInfo] = @[]
    var tempSectionInfo:SectionInfo
    var memoryCursor:uint64 = 0
    var symbolTable:ptr SymbolTableEntry = cast[ptr SymbolTableEntry](unsafeAddr(fileBuffer[0]) + cast[int](fileHeader.PointerToSymbolTable))
    var symbolTableCursor:ptr SymbolTableEntry = nil
    var relocationTableCursor:ptr RelocationTableEntry = nil
    var sectionIndex:int = 0
    var isExternal:bool = false
    var isInternal:bool = false
    var patchAddress:uint64 = 0
    var stringTableOffset:int = 0
    var symbolName:string = ""
    var externalFunctionCount:int = 0
    var externalFunctionStoreAddress:ptr uint64 = nil
    var tempFunctionAddr:uint64 = 0
    var delta:uint64 = 0
    var tempPointer:ptr uint32 = nil
    var entryAddress:uint64 = 0
    var sectionStartAddress:uint64 = 0
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
    externalFunctionStoreAddress = cast[ptr uint64](totalSize+cast[uint64](allocatedMemory))
    for i in countup(0,cast[int](fileHeader.NumberOfSections-1)):
        copyMem(cast[LPVOID](cast[uint64](allocatedMemory)+memoryCursor),unsafeaddr(fileBuffer[0])+cast[int](sectionHeaderCursor.PointerToRawData),sectionHeaderCursor.SizeOfRawData)
        memoryCursor += sectionHeaderCursor.SizeOfRawData
        sectionHeaderCursor+=1
    echo "[+] Sections are copied!"
    # Relocations start
    for i in countup(0,cast[int](fileHeader.NumberOfSections-1)):
        echo "  [+] Relocations for section: ",sectionInfoList[i].Name
        relocationTableCursor = cast[ptr RelocationTableEntry](unsafeAddr(fileBuffer[0]) + cast[int](sectionInfoList[i].SectionHeaderPtr.PointerToRelocations))
        for relocationCount in countup(0, cast[int](sectionInfoList[i].SectionHeaderPtr.NumberOfRelocations)-1):
            symbolTableCursor = cast[ptr SymbolTableEntry](symbolTable + cast[int](relocationTableCursor.SymbolTableIndex))
            sectionIndex = cast[int](symbolTableCursor.SectionNumber - 1)
            isExternal = (symbolTableCursor.StorageClass == IMAGE_SYM_CLASS_EXTERNAL and symbolTableCursor.SectionNumber == 0)
            isInternal = (symbolTableCursor.StorageClass == IMAGE_SYM_CLASS_EXTERNAL and symbolTableCursor.SectionNumber != 0)
            patchAddress = cast[uint64](allocatedMemory) + sectionInfoList[i].SectionOffset + cast[uint64](relocationTableCursor.VirtualAddress - sectionInfoList[i].SectionHeaderPtr.VirtualAddress)
            if(isExternal):
                # If it is function
                stringTableOffset = cast[int](symbolTableCursor.First.value[1])
                symbolName = $(cast[ptr byte](symbolTable+cast[int](fileHeader.NumberOfSymbols))+stringTableOffset)
                tempFunctionAddr = GetExternalFunctionAddress(symbolName)
                if(tempFunctionAddr != 0):
                    (externalFunctionStoreAddress + externalFunctionCount)[] = tempFunctionAddr
                    delta = (cast[uint64](externalFunctionStoreAddress) + cast[uint64](externalFunctionCount)) - cast[uint64](patchAddress) - 4
                    tempPointer = cast[ptr uint32](patchAddress)
                    tempPointer[] = cast[uint32](delta)
                    externalFunctionCount+=1
                else:
                    echo "[!] Unknown symbol resolution! [",symbolName,"]"
                    return false
            else:
                if(sectionIndex >= sectionInfoList.len or sectionIndex < 0):
                    echo "[!] Error on symbol section index! [",sectionIndex,"]"
                    return false
                sectionStartAddress = cast[uint64](allocatedMemory) + sectionInfoList[sectionIndex].SectionOffset
                if(isInternal):
                    for internalCount in countup(0,sectionInfoList.len-1):
                        if(sectionInfoList[internalCount].Name == ".text"):
                            sectionStartAddress = cast[uint64](allocatedMemory) + sectionInfoList[internalCount].SectionOffset
                            break
                ApplyGeneralRelocations(patchAddress,sectionStartAddress,relocationTableCursor.Type,symbolTableCursor.Value)
            relocationTableCursor+=1
    echo "[+] Relocations are done!"
    for i in countup(0,cast[int](fileHeader.NumberOfSymbols-1)):
        symbolTableCursor = symbolTable + i
        if(functionName == $(addr(symbolTableCursor.First.Name[0]))):
            echo "[+] Found the entry: ",functionName
            entryAddress = cast[uint64](allocatedMemory) + sectionInfoList[symbolTableCursor.SectionNumber-1].SectionOffset + symbolTableCursor.Value
    if(entryAddress == 0):
        echo "[!] Entry not found!"
        return false
    var entryPtr:COFFEntry = cast[COFFEntry](entryAddress)
    echo "[+] ",functionName," entry found! "
    echo "[+] Executing..."
    entryPtr(unsafeaddr(argumentBuffer[0]),cast[uint32](argumentBuffer.len))
    return true

when isMainModule:
    PrintBanner()
    if(paramCount() < 2 or paramCount() > 3):
        DisplayHelp()
        quit(0)
    var fileBuffer:seq[byte] = ReadFileFromDisk(paramStr(1))
    var argumentBuffer:seq[byte] = @[]
    if(fileBuffer.len == 0):
        echo "[!] Error on file read! [",paramStr(1),"]"
        quit(0)
    echo "[+] File is read!"
    if(paramCount() == 3):
        argumentBuffer = HexStringToByteArray(paramStr(3),paramStr(3).len)
        if(argumentBuffer.len == 0):
            echo "[!] Error on unhexlifying the argument!"
            quit(0)
        echo "[+] Argument is unhexlified!"
    if(not RunCOFF(paramStr(2),fileBuffer,argumentBuffer)):
        echo "[!] Error on executing file!"
        VirtualFree(allocatedMemory, 0, MEM_RELEASE)
        quit(0)
    echo "[+] COFF File is Executed!"
    var outData:ptr char = BeaconGetOutputData(NULL);
    if(outData != NULL):
        echo "[+] Output Below:\n\n"
        echo $outData
    VirtualFree(allocatedMemory, 0, MEM_RELEASE)

    

        
    