# NiCOFF

Basically, NiCOFF is a COFF and BOF file loader written in Nim. NiCOFF reads a BOF or COFF file, parses and executes it in the memory. Whole project is based on [Yasser](https://twitter.com/Yas_o_h)'s and [Kevin](https://twitter.com/kev169)'s COFF Loader projects. Both the loader and beacon functions in these projects were rewritten in Nim. 

# Compilation

You can directly compile the source code with the following command:

` nim c -d:release Main.nim -o NiCOFF.exe`

In case you get the error "cannot open file", you should also install required dependencies:

`nimble install ptr_math winim` 

# Usage

NiCOFF can take up to three arguments which are BOF or COFF file path, started function entry, and optional BOF arguments (you can check [Kevin's script](https://github.com/trustedsec/COFFLoader/blob/main/beacon_generate.py)).

```
NiCOFF.exe go test64.out 0400000005000000
```

# References

- https://github.com/trustedsec/COFFLoader
- https://github.com/Yaxser/COFFLoader2
- https://0xpat.github.io/Malware_development_part_8/
- https://blog.cloudflare.com/how-to-execute-an-object-file-part-1/
