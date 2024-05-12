unit Case51_SDL_and_modern_opengl;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  ctGL,
  ctGLU,
  libSDL2,
  libSDL2_ttf,
  libSDL2_image,
  DeepStar.Utils,
  SDL2_Tutorials.Utils;

const
  //Screen dimension constants
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

var
  //The window we'll be rendering to
  gWindow: PSDL_Window = nil;

  //OpenGL context
  gContext: TSDL_GLContext = nil;

  //Render flag
  gRenderQuad: boolean = true;

  // Font
  gFont: PTTF_Font;

  //Graphics program
  gProgramID: GLuint = 0;
  gVertexPos2DLocation: GLint = -1;
  gVBO: GLuint = 0;
  gIBO: GLuint = 0;

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

//Shader loading utility programs
procedure PrintProgramLog(programs: GLuint);
procedure PrintShaderLog(shader: GLuint);

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
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

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
  vertexShader, fragmentShader: GLuint;
  vShaderCompiled, fShaderCompiled, programSuccess: GLint;
  vertexData: TArr_GLfloat;
  vertexShaderSource, fragmentShaderSource: PAnsiChar;
  indexData: TArr_GLuint;
begin
  success := true;

  OpenGL_InitializeAdvance;

  //Generate program
  gProgramID := glCreateProgram();

  //Create vertex shader
  vertexShader := GLuint(0);
  vertexShader := glCreateShader(GL_VERTEX_SHADER);

  vertexShaderSource := (
    '#version 140 ' + LineEnding +
    'in vec2 LVertexPos2D;' + LineEnding +
    'void main() ' + LineEnding +
    '{' + LineEnding +
    '   gl_Position = vec4( LVertexPos2D.x, LVertexPos2D.y, 0, 1 );' + LineEnding +
    '}').ToPAnsiChar;

  //Set vertex source
  glShaderSource(vertexShader, 1, @vertexShaderSource, nil);

  //Compile vertex source
  glCompileShader(vertexShader);

  //Check vertex shader for errors
  vShaderCompiled := GLint(GL_FALSE);
  glGetShaderiv(vertexShader, GL_COMPILE_STATUS, @vShaderCompiled);
  if vShaderCompiled <> GL_TRUE then
  begin
    WriteLnF('Unable to compile vertex shader %d!', [vertexShader]);
    printShaderLog(vertexShader);
    success := false;
  end
  else
  begin
    //Attach vertex shader to program
    glAttachShader(gProgramID, vertexShader);


    //Create fragment shader
    fragmentShader := GLuint(0);
    fragmentShader := glCreateShader(GL_FRAGMENT_SHADER);

    //Get fragment source
    fragmentShaderSource := (
      '#version 140' + LineEnding +
      'out vec4 LFragment; ' + LineEnding +
      'void main()' + LineEnding +
      '{' + LineEnding +
      '   LFragment = vec4( 1.0, 1.0, 1.0, 1.0 ); ' + LineEnding +
      '}').ToPAnsiChar;

    //Set fragment source
    glShaderSource(fragmentShader, 1, @fragmentShaderSource, nil);

    //Compile fragment source
    glCompileShader(fragmentShader);

    //Check fragment shader for errors
    fShaderCompiled := GLint(GL_FALSE);
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, @fShaderCompiled);
    if fShaderCompiled <> GL_TRUE then
    begin
      WriteLnF('Unable to compile fragment shader %d!', [fragmentShader]);
      printShaderLog(fragmentShader);
      success := false;
    end
    else
    begin
      //Attach fragment shader to program
      glAttachShader(gProgramID, fragmentShader);

      //Link program
      glLinkProgram(gProgramID);

      //Check for errors
      programSuccess := GLint(GL_TRUE);
      glGetProgramiv(gProgramID, GL_LINK_STATUS, @programSuccess);
      if programSuccess <> GL_TRUE then
      begin
        WriteLnF('Error linking program %d!', [gProgramID]);
        printProgramLog(gProgramID);
        success := false;
      end
      else
      begin
        //Get vertex attribute location
        gVertexPos2DLocation := glGetAttribLocation(gProgramID, 'LVertexPos2D');
        if gVertexPos2DLocation = -1 then
        begin
          WriteLn('LVertexPos2D is not a valid glsl program variable!');
          success := false;
        end
        else
        begin
          //Initialize clear color
          glClearColor(0, 0, 0, 1);

          //VBO data
          vertexData := TArr_GLfloat(
            [
              -0.5, -0.5,
               0.5, -0.5,
               0.5,  0.5,
              -0.5,  0.5
            ]);

          //IBO data
          indexData := TArr_GLuint([0, 1, 2, 3]);

          //Create VBO
          glGenBuffers(1, @gVBO);
          glBindBuffer(GL_ARRAY_BUFFER, gVBO);
          glBufferData(GL_ARRAY_BUFFER, 2 * 4 * SizeOf(GLfloat), @vertexData[0], GL_STATIC_DRAW);

          //Create IBO
          glGenBuffers(1, @gIBO);
          glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gIBO);
          glBufferData(GL_ELEMENT_ARRAY_BUFFER, 4 * SizeOf(GLuint), @indexData[0], GL_STATIC_DRAW);
        end;
      end;
    end;
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

procedure render();
begin
  //Clear color buffer
  glClear(GL_COLOR_BUFFER_BIT);

  //Render quad
  if gRenderQuad then
  begin
    //Bind program
    glUseProgram(gProgramID);

    //Enable vertex position
    glEnableVertexAttribArray(gVertexPos2DLocation);

    //Set vertex data
    glBindBuffer(GL_ARRAY_BUFFER, gVBO);
    glVertexAttribPointer(gVertexPos2DLocation, 2, GL_FLOAT, false, 2 * SizeOf(GLfloat), nil);

    //Set index data and render
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gIBO);
    glDrawElements(GL_TRIANGLE_FAN, 4, GL_UNSIGNED_INT, nil);

    //Disable vertex position
    glDisableVertexAttribArray(gVertexPos2DLocation);

    //Unbind program
    glUseProgram(0);
  end;
end;

procedure Close();
begin
  //Deallocate program
  glDeleteProgram(gProgramID);

  SDL_DestroyWindow(gWindow);
  gWindow := nil;

  // Quit SDL subsystems
  TTF_Quit();
  IMG_Quit();
  SDL_Quit();
end;

procedure printProgramLog(programs: GLuint);
var
  infoLogLength, maxLength: integer;
  infoLog: TArr_chr;
begin
  //Make sure name is shader
  if glIsProgram(programs) then
  begin
    //Programs log length
    infoLogLength := 0;
    maxLength := infoLogLength;

    //Get info string length
    glGetProgramiv(programs, GL_INFO_LOG_LENGTH, @maxLength);

    //Allocate string
    infoLog := TArr_chr(nil);
    SetLength(infoLog, maxLength);

    //Get info log
    glGetProgramInfoLog(programs, maxLength, @infoLogLength, @infoLog);
    if infoLogLength > 0 then
    begin
      //Print Log
      WriteLnF('%s', [string.Create(infoLog)]);
    end;
  end
  else
  begin
    WriteLnF('Name %d is not a programs;', [programs]);
  end;
end;

procedure printShaderLog(shader: GLuint);
var
  infoLogLength, maxLength: integer;
  infoLog: TArr_chr;
begin
  //Make sure name is shader
  if glIsShader(shader) then
  begin
    //Shader log length
    infoLogLength := 0;
    maxLength := infoLogLength;

    //Get info string length
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, @maxLength);

    //Allocate string
    infoLog := TArr_chr(nil);
    SetLength(infoLog, maxLength);

    //Get info log
    glGetShaderInfoLog(shader, maxLength, @infoLogLength, @infoLog);
    if infoLogLength > 0 then
    begin
      //Print Log
      WriteLnF('%s', [string.Create(infoLog)]);
    end;
  end
  else
  begin
    WriteLnF('Name %d is not a shader', [shader]);
  end;
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
      SDL_GL_SwapWindow(gWindow);
    end;

    //Disable text input
    SDL_StopTextInput();
  end;

  // Free resources and close SDL
  Close();
end;

end.
