# NiCOFF

Basically, NiCOFF is a COFF and BOF file loader written in Nim. NiCOFF reads a BOF or COFF file, parses and executes it in the memory. Whole project is based on [Yasser](https://twitter.com/Yas_o_h)'s and [Kevin](https://twitter.com/kev169)'s COFF Loader projects. Both the loader and beacon functions in these projects were rewritten in Nim. 

# Compilation

You can directly compile the source code with the following command:

`nim c -d:release -o:NiCOFF.exe Main.nim`

In case you get the error "cannot open file", you should also install required dependencies:

`nimble install ptr_math winim` 

# Usage

NiCOFF can take up to three arguments which are BOF or COFF file path, started function entry (you may want to change function pointer), and optional BOF arguments (you can check [Kevin's script](https://github.com/trustedsec/COFFLoader/blob/main/beacon_generate.py)).

```
PS C:\Users\test\Desktop\NiCOFF\bin> .\NiCOFF.exe .\ipconfig.x64.o go
 ______  _  ______ _____  _______ _______
|  ___ \(_)/ _____) ___ \(_______|_______)
| |   | |_| /    | |   | |_____   _____
| |   | | | |    | |   | |  ___) |  ___)
| |   | | | \____| |___| | |     | |
|_|   |_|_|\______)_____/|_|     |_|

                @R0h1rr1m

[+] File is read!
[+] Sections are copied!
  [+] Relocations for section: .text
  [+] Relocations for section: .data
  [+] Relocations for section: .bss
  [+] Relocations for section: .xdata
  [+] Relocations for section: .pdata
  [+] Relocations for section: .rdata
  [+] Relocations for section: /4
[+] Relocations are done!
[+] Trying to find the entry: go
[+] go entry found!
[+] Executing...
[+] COFF File is Executed!
[+] Output Below:

```

# References

- https://github.com/trustedsec/COFFLoader
- https://github.com/Yaxser/COFFLoader2
- https://0xpat.github.io/Malware_development_part_8/
- https://blog.cloudflare.com/how-to-execute-an-object-file-part-1/
