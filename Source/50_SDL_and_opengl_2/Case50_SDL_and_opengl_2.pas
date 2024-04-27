unit Case50_SDL_and_opengl_2;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  GL,
  glu,
  libSDL2,
  libSDL2_ttf,
  libSDL2_image,
  DeepStar.Utils,
  Case49_mutexes_and_conditions.Texture;

const
  //Screen dimension constants
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;
  SCREEN_FPS = 60;

var
  //The window we'll be rendering to
  gWindow: PSDL_Window;

  //OpenGL context
  gContext: TSDL_GLContext;

  //Render flag
  gRenderQuad: boolean = true;

  // Font
  gFont: PTTF_Font;

  //Scene textures
  gSplashTexture: TTexture;

  //The protective mutex
  gBufferLock: PSDL_Mutex = nil;

  //The conditions
  gCanProduce: PSDL_Cond = nil;
  gCanConsume: PSDL_Cond = nil;

  //The "data buffer"
  gData: integer = -1;

procedure Main;
//Starts up SDL, creates window, and initializes OpenGL
function Init(): boolean;
//Initializes matrices and clear color
function InitGL(): boolean;
//Input handler
procedure HandleKeys(key: char; x, y: integer);
//Per frame update
procedure Update();
//Renders quad to the screen
procedure Render();
// Frees media and shuts down SDL
procedure Close();

implementation

function Init(): boolean;
var
  success: boolean;
begin
  success := true;

  // Initialize SDL
  if SDL_Init(SDL_INIT_VIDEO or SDL_INIT_TIMER) < 0 then
  begin
    WriteLnF('SDL could not initialize! SDL_Error: %s', [SDL_GetError()]);
    success := false;
  end
  else
  begin
    //Use OpenGL 2.1
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);

    //Create window
    gWindow := SDL_CreateWindow(
      'SDL Tutorial',
      SDL_WINDOWPOS_UNDEFINED,
      SDL_WINDOWPOS_UNDEFINED,
      SCREEN_WIDTH,
      SCREEN_HEIGHT,
      SDL_WINDOW_SHOWN or SDL_WINDOW_OPENGL);

    if gWindow = nil then
    begin
      WriteLn('Window could not be created! SDL Error: %s', SDL_GetError());
      success := false;
    end
    else
    begin
      //Create context
      gContext := SDL_GL_CreateContext(gWindow);
      if gContext = nil then
      begin
        WriteLnF('OpenGL context could not be created! SDL Error: %s', [SDL_GetError()]);
        success := false;
      end
      else
      begin
        //Use Vsync
        if SDL_GL_SetSwapInterval(1) < 0 then
        begin
          WriteLnF('Warning: Unable to set VSync! SDL Error: %s', [SDL_GetError()]);
        end;

        //Initialize OpenGL
        if not InitGL() then
        begin
          WriteLn('Unable to initialize OpenGL!');
          success := false;
        end;
      end;
    end;
  end;

  Result := success;
end;

function InitGL(): boolean;
var
  success: boolean;
  error: TGLenum;
begin
  success := true;
  error := TGLenum(GL_NO_ERROR);

  //Initialize Projection Matrix
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();

  //Check for error
  error := glGetError();
  if error <> GL_NO_ERROR then
  begin
    WriteLnF('Error initializing OpenGL! %s', [gluErrorString(error)]);
    success := false;
  end;

  //Initialize Modelview Matrix
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  //Check for error
  error := glGetError();
  if error <> GL_NO_ERROR then
  begin
    WriteLnF('Error initializing OpenGL! %s', [gluErrorString(error)]);
    success := false;
  end;

  //Initialize clear color
  glClearColor(0, 0, 0, 1);

  //Check for error
  error := glGetError();
  if error <> GL_NO_ERROR then
  begin
    WriteLnF('Error initializing OpenGL! %s', [gluErrorString(error)]);
    success := false;
  end;

  Result := success;
end;

procedure HandleKeys(key: char; x, y: integer);
begin
  if key = 'q' then
    gRenderQuad := not gRenderQuad;
end;

procedure Update();
begin
end;

procedure Render();
begin
  //Clear color buffer
  glClear(GL_COLOR_BUFFER_BIT);

  //Render quad
  if gRenderQuad then
  begin
    glBegin(GL_QUADS);
    glVertex2f(-0.5, -0.5);
    glVertex2f(0.5, -0.5);
    glVertex2f(0.5, 0.5);
    glVertex2f(-0.5, 0.5);
    glEnd();
  end;
end;

procedure Close();
begin
  SDL_DestroyWindow(gWindow);
  gWindow := nil;

  // Quit SDL subsystems
  TTF_Quit();
  IMG_Quit();
  SDL_Quit();
end;

procedure Main;
var
  quit: boolean;
  e: TSDL_Event;
  x, y: integer;
begin
  // Start up SDL and create window
  if not Init then
  begin
    WriteLn('Failed to initialize!');
  end
  else
  begin
    // Main loop flag
    quit := false;
    //Event handler
    e := Default(TSDL_Event);

    //Enable text input
    SDL_StartTextInput();

    // While application is running
    while not quit do
    begin
      while SDL_PollEvent(@e) <> 0 do
      begin
        if e.type_ = SDL_QUIT_EVENT then
        begin
          quit := true;
        end
        else if e.type_ = SDL_KEYDOWN then
        begin
          case e.key.keysym.sym of
            SDLK_ESCAPE: quit := true;
          end;
        end;

        if e.type_ = SDL_TEXTINPUT then
        begin
          x := 0; y := 0;
          SDL_GetMouseState(@x, @y);
          HandleKeys(e.Text.Text[0], x, y);
        end;
      end;

      //Render quad
      Render();

      //Update screen
			SDL_GL_SwapWindow( gWindow );
    end;

    //Disable text input
		SDL_StopTextInput();
  end;

  // Free resources and close SDL
  Close();
end;

end.
