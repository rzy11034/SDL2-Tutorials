unit Case35_window_events.Windows;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  DeepStar.UString,
  libSDL2;

const
  // Screen dimension constants
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

type
  TWindows = class(TObject)
  private
    //Window data
    _Window: PSDL_Window;

    _Renderer: PSDL_Renderer;

    //Window dimensions
    _Width: integer;
    _Height: integer;

    //Window focus
    _MouseFocus: boolean;
    _KeyboardFocus: boolean;
    _FullScreen: boolean;
    _Minimized: boolean;

  public
    constructor Create;
    destructor Destroy; override;

    //Creates window
    function Init(): boolean;

    //Creates renderer from internal window
    function createRenderer(): PSDL_Renderer;

    //Handles window events
    procedure HandleEvent(var e: TSDL_Event);

    //Deallocates internals
    //void free();

    //Window dimensions
    function GetWidth(): integer;
    function GetHeight(): integer;

    //Window focii
    function HasMouseFocus(): boolean;
    function HasKeyboardFocus(): boolean;
    function IsMinimized(): boolean;
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

function TWindows.createRenderer(): PSDL_Renderer;
begin
  Result := SDL_CreateRenderer(_Window, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
end;

destructor TWindows.Destroy;
begin
  SDL_DestroyWindow(_Window);
  inherited Destroy;
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
  updateCaption: Boolean;
  caption: TStringBuilder;
begin
  //Window event occured
	if  e.type_ = SDL_WINDOWEVENT then
  begin
    //Caption update flag
		updateCaption := false;

		case e.window.event  of
      //Get new dimensions and repaint on window size change
			SDL_WINDOWEVENT_SIZE_CHANGED:
      begin
        _Width := e.window.data1;
			  _Height := e.window.data2;
			  SDL_RenderPresent( _Renderer );
      end;

			//Repaint on exposure
			SDL_WINDOWEVENT_EXPOSED:
      begin
        SDL_RenderPresent( _Renderer );
      end;


			//Mouse entered window
			SDL_WINDOWEVENT_ENTER:
      begin
        _MouseFocus := true;
			  updateCaption := true;
      end;

			//Mouse left window
			SDL_WINDOWEVENT_LEAVE:
      begin
        _MouseFocus := false;
			  updateCaption := true;
      end;


			//Window has keyboard focus
			SDL_WINDOWEVENT_FOCUS_GAINED:
      begin
        _KeyboardFocus := true;
			  updateCaption := true;
      end;

			//Window lost keyboard focus
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
    end;

		//Update window caption with new data
		if  updateCaption  then
    begin
      caption := TStringBuilder.Create();
      try
        caption.Append('SDL Tutorial - MouseFocus:');
        if _MouseFocus then
          caption.Append('On')
        else
          caption.Append('Off');

        caption.Append(' KeyboardFocus:');
        if _KeyboardFocus then
          caption.Append('On')
        else
          caption.Append('Off');

			SDL_SetWindowTitle( _Window, caption.ToString.ToPAnsiChar);
      finally
        caption.Free;
      end;
    end;
  end
  //Enter exit full screen on return key
	else if ( e.type_ = SDL_KEYDOWN) and( e.key.keysym.sym = SDLK_RETURN )then
  begin
    if _FullScreen then
    begin
      SDL_SetWindowFullscreen( _Window, 0 );
			_FullScreen := false;
    end
		else
    begin
      SDL_SetWindowFullscreen( _Window, SDL_WINDOW_FULLSCREEN_DESKTOP );
			_FullScreen := true;
			_Minimized := false;
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
  _Window := SDL_CreateWindow(
    'SDL Tutorial',
    SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOWPOS_UNDEFINED,
    SCREEN_WIDTH, SCREEN_HEIGHT,
    SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE);

  if _Window <> nil then
  begin
    _MouseFocus := true;
    _KeyboardFocus := true;
    _Width := SCREEN_WIDTH;
    _Height := SCREEN_HEIGHT;
  end;

  Result := _Window <> nil;
end;

function TWindows.IsMinimized(): boolean;
begin
  Result := _Minimized;
end;

end.
