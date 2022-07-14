import winim/lean

#[
typedef struct {
    char* original; /* the original buffer [so we can free it] */
    char* buffer;   /* current pointer into our buffer */
    int    length;   /* remaining length of data */
    int    size;     /* total size of this buffer */
} datap;
]#
type
    Datap* {.bycopy,packed.} = object
        original*: ptr char
        buffer*: ptr char
        length*: int
        size*: int
#[
typedef struct {
    char* original; /* the original buffer [so we can free it] */
    char* buffer;   /* current pointer into our buffer */
    int    length;   /* remaining length of data */
    int    size;     /* total size of this buffer */
} formatp;
]#
    Formatp* {.bycopy,packed.} = object
        original*: ptr char
        buffer*: ptr char
        length*: int
        size*: int


# void BeaconDataParse(datap* parser, char* buffer, int size)
proc BeaconDataParse(parser:ptr Datap,buffer: ptr char,size:int):void{.stdcall.} =
    discard

# int     BeaconDataInt(datap* parser);
proc BeaconDataInt(parser:ptr Datap):int{.stdcall.} =
    discard

# short   BeaconDataShort(datap* parser);
proc BeaconDataShort(parser:ptr Datap):int16{.stdcall.} =
    discard

# int     BeaconDataLength(datap* parser);
proc BeaconDataLength(parser:ptr Datap):int{.stdcall.} =
    discard

# char* BeaconDataExtract(datap* parser, int* size);
proc BeaconDataExtract(parser:ptr Datap,size:ptr int):ptr char{.stdcall.} =
    discard

# void    BeaconFormatAlloc(formatp* format, int maxsz);
proc BeaconFormatAlloc(format:ptr Formatp,maxsz:int):void{.stdcall.} =
    discard

# void    BeaconFormatReset(formatp* format);
proc BeaconFormatReset(format:ptr Formatp):void{.stdcall.} =
    discard

# void    BeaconFormatFree(formatp* format);
proc BeaconFormatFree(format:ptr Formatp):void{.stdcall.} =
    discard

# void    BeaconFormatAppend(formatp* format, char* text, int len);
proc BeaconFormatAppend(format:ptr Formatp,text:ptr char,len:int):void{.stdcall.} =
    discard

# void    BeaconFormatPrintf(formatp* format, char* fmt, ...); --> TODO VARARGS
proc BeaconFormatPrintf(format:ptr Formatp,fmt:ptr char):void{.stdcall.} =
    discard

# char* BeaconFormatToString(formatp* format, int* size);
proc BeaconFormatToString(format:ptr Formatp,size:ptr int):ptr char{.stdcall.} =
    discard

# void    BeaconFormatInt(formatp* format, int value);
proc BeaconFormatInt(format:ptr Formatp,value:int):void{.stdcall.} =
    discard

const
    CALLBACK_OUTPUT      = 0x0
    CALLBACK_OUTPUT_OEM  = 0x1e
    CALLBACK_ERROR       = 0x0d
    CALLBACK_OUTPUT_UTF8 = 0x20

# void   BeaconPrintf(int type, char* fmt, ...); TODO varargs
proc BeaconPrintf(typeArg:int,fmt:ptr char):void{.stdcall.} =
    discard

#void   BeaconOutput(int type, char* data, int len);
proc BeaconOutput(typeArg:int,data:ptr char,len:int):void{.stdcall.} =
    discard

# Token Functions 

# BOOL   BeaconUseToken(HANDLE token);
proc BeaconUseToken(token: HANDLE):BOOL{.stdcall.} =
    discard

# void   BeaconRevertToken();
proc BeaconRevertToken():void{.stdcall.} =
    discard

# BOOL   BeaconIsAdmin();
proc BeaconIsAdmin():BOOL{.stdcall.} =
    discard

# Spawn+Inject Functions 
# void   BeaconGetSpawnTo(BOOL x86, char* buffer, int length);
proc BeaconGetSpawnTo(x86: BOOL, buffer:ptr char, length:int):void{.stdcall.} =
    discard

# BOOL BeaconSpawnTemporaryProcess(BOOL x86, BOOL ignoreToken, STARTUPINFO* sInfo, PROCESS_INFORMATION* pInfo);
proc BeaconSpawnTemporaryProcess(x86: BOOL, ignoreToken:BOOL, sInfo:ptr STARTUPINFO, pInfo: ptr PROCESS_INFORMATION):BOOL{.stdcall.} =
    discard

# void   BeaconInjectProcess(HANDLE hProc, int pid, char* payload, int p_len, int p_offset, char* arg, int a_len);
proc BeaconInjectProcess(hProc: HANDLE, pid:int, payload:ptr char, p_len: int,p_offset: int, arg:ptr char, a_len:int):void{.stdcall.} =
    discard

# void   BeaconInjectTemporaryProcess(PROCESS_INFORMATION* pInfo, char* payload, int p_len, int p_offset, char* arg, int a_len);
proc BeaconInjectTemporaryProcess(pInfo: ptr PROCESS_INFORMATION, payload:ptr char, p_len: int,p_offset: int, arg:ptr char, a_len:int):void{.stdcall.} =
    discard

# void   BeaconCleanupProcess(PROCESS_INFORMATION* pInfo);
proc BeaconCleanupProcess(pInfo: ptr PROCESS_INFORMATION):void{.stdcall.} =
    discard

# Utility Functions 
# BOOL   toWideChar(char* src, wchar_t* dst, int max); TODO FIX
proc toWideChar(src:ptr char,dst: ptr char ,max: int):BOOL{.stdcall.} =
    discard

# uint32_t swap_endianess(uint32_t indata);
proc swap_endianess(indata:uint32):uint32{.stdcall.} =
    discard

# char* BeaconGetOutputData(int* outsize);
proc BeaconGetOutputData(outsize:ptr int):ptr char{.stdcall.} =
    discard

var functionAddresses*:array[23,tuple[name: string, address: uint64]] = [
    ("BeaconDataParse", cast[uint64](BeaconDataParse)),
    ("BeaconDataInt", cast[uint64](BeaconDataInt)),
    ("BeaconDataShort", cast[uint64](BeaconDataShort)),
    ("BeaconDataLength", cast[uint64](BeaconDataLength)),
    ("BeaconDataExtract", cast[uint64](BeaconDataExtract)),
    ("BeaconFormatAlloc", cast[uint64](BeaconFormatAlloc)),
    ("BeaconFormatReset", cast[uint64](BeaconFormatReset)),
    ("BeaconFormatFree", cast[uint64](BeaconFormatFree)),
    ("BeaconFormatAppend", cast[uint64](BeaconFormatAppend)),
    ("BeaconFormatPrintf", cast[uint64](BeaconFormatPrintf)),
    ("BeaconFormatToString", cast[uint64](BeaconFormatToString)),
    ("BeaconFormatInt", cast[uint64](BeaconFormatInt)),
    ("BeaconPrintf", cast[uint64](BeaconPrintf)),
    ("BeaconOutput", cast[uint64](BeaconOutput)),
    ("BeaconUseToken", cast[uint64](BeaconUseToken)),
    ("BeaconRevertToken", cast[uint64](BeaconRevertToken)),
    ("BeaconIsAdmin", cast[uint64](BeaconIsAdmin)),
    ("BeaconGetSpawnTo", cast[uint64](BeaconGetSpawnTo)),
    ("BeaconSpawnTemporaryProcess", cast[uint64](BeaconSpawnTemporaryProcess)),
    ("BeaconInjectProcess", cast[uint64](BeaconInjectProcess)),
    ("BeaconInjectTemporaryProcess", cast[uint64](BeaconInjectTemporaryProcess)),
    ("BeaconCleanupProcess", cast[uint64](BeaconCleanupProcess)),
    ("toWideChar", cast[uint64](toWideChar))
]