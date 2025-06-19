Unix-Like (GNU, Linux, FreeBSD, macOS, etc.):
```
gcc -O3 -flto -shared -fPIC -o libmesh.so mesh.c
mcs -optimize+ mesh.cs main.cs -out:main
./main
```

Windows
```
cl /LD /GL /O2 mesh.c /link /DEF:libmesh.def /OUT:libmesh.dll /IMPLIB:libmesh.lib
csc /optimize mesh.cs main.cs /out:main.exe
main.exe
```

Compilers used:

| OS | Language | Version |
| -- | -------- | ------- |
| Debian 12 GNU/Linux | C  | GCC 12.2.0-14                     |
| Debian 12 GNU/Linux | C# | Mono C# compiler version 6.8.0.105|
| Windows 10 | C  | MSVC 19.44.35208                                   |
| Windows 10 | C# | Roslyn Visual C# Compiler version 4.14.0-3.25229.6 |
