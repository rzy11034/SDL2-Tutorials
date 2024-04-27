unit SDL2_Tutorials.Header_file_supplement;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  dynlibs,
  libSDL2;

type
  PPSDL_SpinLock = ^PSDL_SpinLock;
  PSDL_SpinLock = ^TSDL_SpinLock;
  TSDL_SpinLock = integer;

{$REGION 'SDL_atomic.h'}
type
  TSDL_AtomicLock = function(lock: PSDL_SpinLock): boolean; cdecl;
  TSDL_AtomicUnlock = procedure(lock: PSDL_SpinLock); cdecl;
var
  SDL_AtomicLock: TSDL_AtomicLock = nil;
  SDL_AtomicUnlock: TSDL_AtomicUnlock = nil;
{$ENDREGION}

procedure Load_SDL_Header_File_Supplement;

implementation

procedure SDL_atomic_h; forward;

var
  VarSDL2LibHandle: TLibHandle;

procedure Load_SDL_Header_File_Supplement;
begin
  VarSDL2LibHandle := dynlibs.LoadLibrary(libSDL2.SDL_LibName);
  SDL_atomic_h;
end;

function GetProcAddress(const aProcName: string): Pointer;
begin
  Result := nil;
  if aProcName = '' then Exit;

  Result := dynlibs.GetProcedureAddress(VarSDL2LibHandle, aProcName);
end;

procedure SDL_atomic_h;
begin
  Pointer(SDL_AtomicLock) := GetProcAddress('SDL_AtomicLock');
  Pointer(SDL_AtomicUnlock) := GetProcAddress('SDL_AtomicUnlock');
end;

end.

