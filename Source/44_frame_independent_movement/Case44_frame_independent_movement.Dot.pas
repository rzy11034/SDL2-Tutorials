unit Case44_frame_independent_movement.Dot;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  libSDL2;

type
  PDot = ^TDot;
  TDot = object
  public const
    //The dimensions of the dot
    DOT_WIDTH = 20;
    DOT_HEIGHT = 20;

    //Maximum axis velocity of the dot
    DOT_VEL = 10;

  private
    _PosX, _PosY: float;
    _VelX, _VelY: float;

  public
    constructor Init;
    destructor Done;

    //Takes key presses and adjusts the dot's velocity
    procedure HandleEvent(var e: TSDL_Event);

    //Moves the dot
    procedure Move(timeStep: float);

    //Shows the dot on the screen
    procedure Render;

  end;

implementation

uses
  Case44_frame_independent_movement;

constructor TDot.Init;
begin
  inherited;

  //Initialize the position
  _PosX := 0;
  _PosY := 0;

  //Initialize the velocity
  _VelX := 0;
  _VelY := 0;
end;

destructor TDot.Done;
begin
  inherited;
end;

procedure TDot.HandleEvent(var e: TSDL_Event);
begin
  //If a key was pressed
  if (e.type_ = SDL_KEYDOWN) and (e.key._repeat = 0) then
  begin
    //Adjust the velocity
    case e.key.keysym.sym of
      SDLK_UP: _VelY -= DOT_VEL;
      SDLK_DOWN: _VelY += DOT_VEL;
      SDLK_LEFT: _VelX -= DOT_VEL;
      SDLK_RIGHT: _VelX += DOT_VEL;
    end;
  end
  //If a key was released
  else if (e.type_ = SDL_KEYUP) and (e.key._repeat = 0) then
  begin
    //Adjust the velocity
    case e.key.keysym.sym of
      SDLK_UP: _VelY += DOT_VEL;
      SDLK_DOWN: _VelY -= DOT_VEL;
      SDLK_LEFT: _VelX += DOT_VEL;
      SDLK_RIGHT: _VelX -= DOT_VEL;
    end;
  end;
end;

procedure TDot.Move(timeStep: float);
begin
  //Move the dot left or right
  _PosX += _VelX * timeStep;

  //If the dot went too far to the left or right
  if _PosX < 0 then
  begin
    _PosX := 0;
  end
  else if _PosX > SCREEN_WIDTH - DOT_WIDTH then
  begin
    _PosX := SCREEN_WIDTH - DOT_WIDTH;
  end;

  //Move the dot up or down
  _PosY += _VelY * timeStep;

  //If the dot went too far up or down
  if _PosY < 0 then
  begin
    _PosY := 0;
  end
  else if _PosY > SCREEN_HEIGHT - DOT_HEIGHT then
  begin
    _PosY := SCREEN_HEIGHT - DOT_HEIGHT;
  end;
end;

procedure TDot.Render();
begin
  //Show the dot
  gDotTexture.Render(trunc(_PosX), trunc(_PosY));
end;

end.

