unit Case37_multiple_displays.Windows;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  DeepStar.Utils,
  libSDL2;

const
  // Screen dimension constants
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

type
  TWindows = class(TObject)
  public type
    TArr_TSDL_Rect = array of TSDL_Rect;

  private
    _DisplayBounds: TArr_TSDL_Rect;
    _TotalDisplays: integer;

    //Window data
    _Window: PSDL_Window;
    _Renderer: PSDL_Renderer;
    _WindowID: integer;
    _WindowDisplayID: integer;

    //Window dimensions
    _Width: integer;
    _Height: integer;

    //Window focus
    _MouseFocus: boolean;
    _KeyboardFocus: boolean;
    _FullScreen: boolean;
    _Minimized: boolean;
    _Shown: boolean;

  public
    constructor Create;
    destructor Destroy; override;

    //Creates window
    function Init(): boolean;

    //Handles window events
    procedure HandleEvent(var e: TSDL_Event);

    //Shows windows contents
    procedure Render();

    //Focuses on window
    procedure Focus();

    //Window dimensions
    function GetWidth(): integer;
    function GetHeight(): integer;

    //Window focii
    function HasMouseFocus(): boolean;
    function HasKeyboardFocus(): boolean;
    function IsMinimized(): boolean;
    function IsShown(): boolean;

    property TotalDisplays:integer read _TotalDisplays write _TotalDisplays;
    property DisplayBounds: TArr_TSDL_Rect read _DisplayBounds write _DisplayBounds;
  end;

implementation

{ TWindows }

constructor TWindows.Create;
begin
  //Initialize non-existant window
  _Window := nil;
  _MouseFocus := false;
  _KeyboardFocus := false;
  _FullScreen := false;
  _Minimized := false;
  _Width := 0;
  _Height := 0;
end;

destructor TWindows.Destroy;
begin
  if _Window <> nil then
    SDL_DestroyWindow(_Window);

  inherited Destroy;
end;

procedure TWindows.Focus();
begin
  //Restore window if needed
  if _Shown then
  begin
    SDL_ShowWindow(_Window);
  end;

  //Move window forward
  SDL_RaiseWindow(_Window);
end;

function TWindows.GetHeight(): integer;
begin
  Result := _Height;
end;

function TWindows.GetWidth(): integer;
begin
  Result := _Width;
end;

procedure TWindows.HandleEvent(var e: TSDL_Event);
var
  updateCaption, switchDisplay: boolean;
  Caption: TStringBuilder;
begin
  //Caption update flag
  updateCaption := false;

  // If an event was detected for this window
  if (e.type_ = SDL_WINDOWEVENT) and (e.window.windowID = _WindowID) then
  begin
    case e.window.event of
      //Window moved
      SDL_WINDOWEVENT_MOVED:
      begin
        _WindowDisplayID := SDL_GetWindowDisplayIndex(_Window);
        updateCaption := true;
      end;

      //Window appeared
      SDL_WINDOWEVENT_SHOWN:
      begin
        _Shown := true;
      end;

      //Window disappeared
      SDL_WINDOWEVENT_HIDDEN:
      begin
        _Shown := false;
      end;

      //Get new dimensions and repaint
      SDL_WINDOWEVENT_SIZE_CHANGED:
      begin
        _Width := e.window.data1;
        _Height := e.window.data2;
        SDL_RenderPresent(_Renderer);
      end;

      //Repaint on expose
      SDL_WINDOWEVENT_EXPOSED:
      begin
        SDL_RenderPresent(_Renderer);
      end;

      //Mouse enter
      SDL_WINDOWEVENT_ENTER:
      begin
        _MouseFocus := true;
        updateCaption := true;
      end;

      //Mouse exit
      SDL_WINDOWEVENT_LEAVE:
      begin
        _MouseFocus := false;
        updateCaption := true;
      end;

      //Keyboard focus gained
      SDL_WINDOWEVENT_FOCUS_GAINED:
      begin
        _KeyboardFocus := true;
        updateCaption := true;
      end;

      //Keyboard focus lost
      SDL_WINDOWEVENT_FOCUS_LOST:
      begin
        _KeyboardFocus := false;
        updateCaption := true;
      end;

      //Window minimized
      SDL_WINDOWEVENT_MINIMIZED:
      begin
        _Minimized := true;
      end;

      //Window maximized
      SDL_WINDOWEVENT_MAXIMIZED:
      begin
        _Minimized := false;
      end;

      //Window restored
      SDL_WINDOWEVENT_RESTORED:
      begin
        _Minimized := false;
      end;

      //Hide on close
      SDL_WINDOWEVENT_CLOSE:
      begin
        SDL_HideWindow(_Window);
      end;
    end;
  end
  else if e.type_ = SDL_KEYDOWN then
  begin
    //Display change flag
    switchDisplay := false;

    //Cycle through displays on up/down
    case e.key.keysym.sym of
      SDLK_UP:
      begin
        _WindowDisplayID += 1;
        switchDisplay := true;
      end;

      SDLK_DOWN:
      begin
        _WindowDisplayID -= 1;
        switchDisplay := true;
      end;
    end;

    //Display needs to be updated
    if switchDisplay then
    begin
      //Bound display index
      if _WindowDisplayID < 0 then
      begin
        _WindowDisplayID := _TotalDisplays - 1;
      end
      else if _WindowDisplayID >= _TotalDisplays then
      begin
        _WindowDisplayID := 0;
      end;

      //Move window to center of next display
      SDL_SetWindowPosition(
        _Window,
        _DisplayBounds[_WindowDisplayID].x + (_DisplayBounds[_WindowDisplayID].w - _Width) div 2,
        _DisplayBounds[_WindowDisplayID].y + (_DisplayBounds[_WindowDisplayID].h - _Height) div 2);

      updateCaption := true;
    end;
  end;

  //Update window caption with new data
  if updateCaption then
  begin
    Caption := TStringBuilder.Create();
    try
      Caption.Append('SDL Tutorial - MouseFocus:');
      if _MouseFocus then
        Caption.Append('On')
      else
        Caption.Append('Off');

      Caption.Append(' KeyboardFocus:');
      if _KeyboardFocus then
        Caption.Append('On')
      else
        Caption.Append('Off');

      SDL_SetWindowTitle(_Window, Caption.ToString.ToPAnsiChar);
    finally
      Caption.Free;
    end;
  end;
end;

function TWindows.HasKeyboardFocus(): boolean;
begin
  Result := _KeyboardFocus;
end;

function TWindows.HasMouseFocus(): boolean;
begin
  Result := _MouseFocus;
end;

function TWindows.Init(): boolean;
begin
  //Create window
  _Window := SDL_CreateWindow
    (
    'SDL Tutorial',
    SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOWPOS_UNDEFINED,
    SCREEN_WIDTH,
    SCREEN_HEIGHT,
    SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE
    );

  if _Window <> nil then
  begin
    _MouseFocus := true;
    _KeyboardFocus := true;
    _Width := SCREEN_WIDTH;
    _Height := SCREEN_HEIGHT;

    //Create renderer for window
    _Renderer := SDL_CreateRenderer(_Window, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
    if _Renderer = nil then
    begin
      WriteLn('Renderer could not be created! SDL Error: %s', SDL_GetError());
      SDL_DestroyWindow(_Window);
      _Window := nil;
    end
    else
    begin
      //Initialize renderer color
      SDL_SetRenderDrawColor(_Renderer, $FF, $FF, $FF, $FF);

      //Grab window identifier
      _WindowID := SDL_GetWindowID(_Window);
      _WindowDisplayID := SDL_GetWindowDisplayIndex(_Window);

      //Flag as opened
      _Shown := true;
    end;
  end
  else
  begin
    WriteLn('Window could not be created! SDL Error: %s', SDL_GetError());
  end;

  Result := (_Window <> nil) and (_Renderer <> nil);
end;

function TWindows.IsMinimized(): boolean;
begin
  Result := _Minimized;
end;

function TWindows.IsShown(): boolean;
begin
  Result := _Shown;
end;

procedure TWindows.Render;
begin
  if not _Minimized then
  begin
    //Clear screen
    SDL_SetRenderDrawColor(_Renderer, $FF, $FF, $FF, $FF);
    SDL_RenderClear(_Renderer);

    //Update screen
    SDL_RenderPresent(_Renderer);
  end;
end;

end.
