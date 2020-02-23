\ read-elf
\
\ Read and parse an ELF binary file, generated by compilers such as gcc.
\
\ Copyright (c) 2006--2009 Krishna Myneni, Creative Consulting for
\   Research and Education, krishna.myneni@ccreweb.org
\
\ Notes:
\
\ 1. The ELF file is assumed to be a 32-bit object file
\
\ Revisions:
\   2009-09-07  km  perform check for SHDRCNT = 0.
\
include ans-words
include strings
include files
include utils
include struct

1 2 2constant short%

struct
  1 4 chars   field  MAGIC
      char%   field  CLASS
      char%   field  BYTEORDER
      char%   field  HVERSION
  1 9 chars   field  PADDING
      short%  field  FILETYPE
      short%  field  ARCHTYPE
      cell%   field  FVERSION
      cell%   field  ENTRY
      cell%   field  PHDRPOS
      cell%   field  SHDRPOS
      cell%   field  FLAGS
      short%  field  HDRSIZE
      short%  field  PHDRENT
      short%  field  PHDRCNT
      short%  field  SHDRENT
      short%  field  SHDRCNT
      short%  field  STRSEC
end-struct elf-header%

\ Defining word for creating an elf file header

: elf-header CREATE  elf-header% %allot drop ;

struct
   cell%  field  SH_NAME
   cell%  field  SH_TYPE
   cell%  field  SH_FLAGS
   cell%  field  SH_ADDR
   cell%  field  SH_OFFSET
   cell%  field  SH_SIZE
   cell%  field  SH_LINK
   cell%  field  SH_INFO
   cell%  field  SH_ALIGN
   cell%  field  SH_ENTSIZE
end-struct section-header%

\ Defining word for creating an elf section header

: section-header CREATE  section-header% %allot drop ;

struct
   cell%  field  ST_NAME
   cell%  field  ST_VALUE
   cell%  field  ST_SIZE
   char%  field  ST_INFO
   char%  field  ST_OTHER
   short% field  ST_SHNDX
end-struct elf-symbol%

\ Defining word for creating an elf symbol table entry

: elf-symbol  CREATE elf-symbol% %allot drop ;
    
\ ELF object file types

0 constant ET_NONE  \ no file type
1 constant ET_REL   \ relocatable file
2 constant ET_EXEC  \ executable file
3 constant ET_DYN   \ shared object file
4 constant ET_CORE  \ core file

\ ELF section types

 0 constant SHT_NULL
 1 constant SHT_PROGBITS   \ program contents
 2 constant SHT_SYMTAB     \ symbol table
 3 constant SHT_STRTAB     \ string table
 4 constant SHT_RELA       
 5 constant SHT_HASH
 6 constant SHT_DYNAMIC
 7 constant SHT_NOTE
 8 constant SHT_NOBITS     \ bss data
 9 constant SHT_REL
10 constant SHT_SHLIB
11 constant SHT_DYNSYM

\ ELF section flags

1 constant SHF_WRITE       \ section should be writable during execution
2 constant SHF_ALLOC       \ section occupies memory during execution
4 constant SHF_EXECINSTR   \ section contains executable machine code

\ ELF symbol types

 0 constant STT_NOTYPE
 1 constant STT_OBJECT     \ data object (variable, array)
 2 constant STT_FUNC       \ function or other executable code
 3 constant STT_SECTION
 4 constant STT_FILE
13 constant STT_LOPROC
15 constant STT_HIPROC


elf-header e1
section-header s1

variable elf-id

: .hex ( n -- | display in hex format )
   BASE @ SWAP HEX ." 0x" . BASE ! ;

: .binary ( n -- | display in hex format )
   BASE @ SWAP BINARY . BASE ! ;

: show-elf-header ( -- )
    CR
    ." magic number: "  e1 MAGIC 1+ 3 TYPE CR
    ." address size: "  e1 CLASS C@ . CR
    ." byte order  : "  e1 BYTEORDER C@ . CR
    ." header ver  : "  e1 HVERSION C@ . CR
    ." file type   : "  e1 FILETYPE w@ . CR
    ." arch type   : "  e1 ARCHTYPE w@ . CR
    ." file ver    : "  e1 FVERSION ? CR
    ." entry point : "  e1 ENTRY @ .hex CR
    ." prog hdr pos: "  e1 PHDRPOS @ .hex CR
    ." sec  hdr pos: "  e1 SHDRPOS @ .hex CR
    ." flags       : "  e1 FLAGS @ .hex CR
    ." header size : "  e1 HDRSIZE w@ . CR
    ." phdrent     : "  e1 PHDRENT w@ . CR
    ." phdrcnt     : "  e1 PHDRCNT w@ . CR
    ." shdrent     : "  e1 SHDRENT w@ . CR
    ." shdrcnt     : "  e1 SHDRCNT w@ . CR
    ." string sec  : "  e1 STRSEC  w@ . CR
    CR
;

: show-section-header ( addr -- )
    CR
    ." name index  : "  dup SH_NAME ? CR
    ." section type: "  dup SH_TYPE ? CR
    ." flag bits   : "  dup SH_FLAGS @ .binary CR
    ." base address: "  dup SH_ADDR @ .hex CR
    ." offset      : "  dup SH_OFFSET ? CR
    ." size        : "  dup SH_SIZE ? CR
    ." link section: "  dup SH_LINK ? CR
    ." specific inf: "  dup SH_INFO ? CR
    ." alignment   : "  dup SH_ALIGN ? CR
    ." size of ent : "  dup SH_ENTSIZE ? CR
    drop CR
;

: show-string-table ( addr -- )
;
    
: open-elf-file ( a u -- | open the elf file)
    R/O open-file ABORT" Unable to open input file!"
    elf-id !
;

: close-elf-file ( -- ) elf-id @ close-file drop ;

: read-elf-header ( -- nbytes) 
    e1 elf-header% %size elf-id @ read-file drop ;

: reposition@section-headers ( -- | reposition file ptr at section headers)
    e1 SHDRPOS @ 0 elf-id @ reposition-file drop ;

: read-section-header ( addr -- nbytes)
    section-header% %size elf-id @ read-file drop ;

: show-elf-raw ( a u -- | open file, read header, and display it )
    open-elf-file
    read-elf-header  CR . ."  bytes read for header." CR
    show-elf-header
    reposition@section-headers
    e1 SHDRCNT w@ 0 ?DO 
      s1 read-section-header  CR . ."  bytes read for section header." CR 
      s1 show-section-header
    LOOP
    close-elf-file
;

\ -----

64 constant MAX_SEC_HDRS
create shbuf section-header% %size MAX_SEC_HDRS * allot

: [sh] ( n -- addr | return address of section header n)
    section-header% %size * shbuf + ;

: read-all-section-hdrs ( -- )
    reposition@section-headers
    shbuf
    e1 SHDRCNT w@ MAX_SEC_HDRS min 0 ?DO
      dup read-section-header drop
      section-header% %size +
    LOOP
    drop ;

: reposition@section ( n -- | reposition the file ptr at specified section)
    [sh] SH_OFFSET @ 0 elf-id @ reposition-file drop ;

create section-names MAX_SEC_HDRS 256 * allot

: read-section-names ( -- | read the section names section)
    e1 STRSEC w@ 
    dup reposition@section   \ move to names section
    [sh] SH_SIZE @ section-names swap elf-id @ read-file 2drop    
;

: get-section-name ( n -- a u | return the section name, given index)
    section-names + dup strlen ;

4096 constant MAX_STRINGS
create strings MAX_STRINGS 256 * allot

: read-string-table ( -- | read the string table section)
    e1 SHDRCNT w@ dup 0= IF drop EXIT THEN
    MAX_SEC_HDRS min 1 ?DO
      i [sh] dup >r SH_TYPE @ SHT_STRTAB = IF
        r@ SH_NAME @ get-section-name s" .strtab" compare
	0= IF
	  r@ SH_OFFSET @ 0 elf-id @ reposition-file drop
	  r> SH_SIZE @ strings swap elf-id @ read-file 2drop
	  unloop EXIT  
	THEN
      THEN 
      r> drop
    LOOP
;

: get-symbol-name ( n -- a u | return the symbol name, given index)
    strings + dup strlen ;

4096 constant MAX_SYMBOLS
create symbols MAX_SYMBOLS elf-symbol% %size * allot
variable nSymbols

: read-symbol-table ( -- | read the symbol table section)
    e1 SHDRCNT w@ dup 0= IF drop EXIT THEN
    MAX_SEC_HDRS min 1 ?DO
      i [sh] SH_TYPE @ SHT_SYMTAB = IF
        i reposition@section
	symbols i [sh] SH_SIZE @ elf-id @ read-file drop
	elf-symbol% %size / nSymbols !
	unloop EXIT
      THEN
    LOOP
;

: show-sections ( -- | display info about sections in tabular form)
    e1 SHDRCNT w@ MAX_SEC_HDRS min 1 ?DO
      i [sh] SH_NAME @ 
      get-section-name CR type
    LOOP
;

: show-symbols ( -- | display info about symbols in tabular form)
    symbols
    nSymbols @ 0 ?DO
      dup ST_NAME @ get-symbol-name type CR
      elf-symbol% %size +
    LOOP
    drop
;

: show-elf ( a u -- | open specified ELF file and display info)
    open-elf-file
    read-elf-header drop
    read-all-section-hdrs
    read-section-names
    read-string-table
    read-symbol-table    
    close-elf-file
    show-sections
    show-symbols
;

      
    