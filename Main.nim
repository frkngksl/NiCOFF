import winim/lean
import cstrutils
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

proc RunCOFF(functionName:string,fileBuffer:seq[byte],argumentBuffer:seq[byte]):bool = 
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


    

        
    