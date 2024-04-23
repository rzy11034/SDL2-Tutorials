unit Case39_tiling.Dot;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  libSDL2,
  Case39_tiling.Tile;

type
  PDot = ^TDot;
  TDot = object
  public type
    TArr_Tile = array of TTile;

  public const
    //The dimensions of the dot
    DOT_WIDTH = 20;
    DOT_HEIGHT = 20;

    //Maximum axis velocity of the dot
    DOT_VEL = 10;

  private
    //Collision box of the dot
		_Box: TSDL_Rect;

    //The velocity of the dot
    _VelX, _VelY: integer;

  public
    constructor Init;
    destructor Done;

    //Takes key presses and adjusts the dot's velocity
    procedure HandleEvent(var e: TSDL_Event);

    //Moves the dot
    procedure Move(tiles: TArr_Tile);

    //Centers the camera over the dot
    procedure SetCamera(var camera: TSDL_Rect);

    //Shows the dot on the screen
    procedure Render(var camera: TSDL_Rect);

  end;

implementation

uses
  Case39_tiling;

constructor TDot.Init;
begin
  inherited;

  //Initialize the collision box
  _Box.x := 0;
  _Box.y := 0;
  _Box.w := DOT_WIDTH;
  _Box.h := DOT_HEIGHT;

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

procedure TDot.Move(tiles: TArr_Tile);
begin
  //Move the dot left or right
  _Box.x += _VelX;

  //If the dot went too far to the left or right or touched a wall
  if (_Box.x < 0) or (_Box.x + DOT_WIDTH > LEVEL_WIDTH) or touchesWall(_Box, tiles) then
  begin
    //move back
    _Box.x -= _VelX;
  end;

  //Move the dot up or down
  _Box.y += _VelY;

  //If the dot went too far up or down or touched a wall
  if (_Box.y < 0) or (_Box.y + DOT_HEIGHT > LEVEL_HEIGHT) or touchesWall(_Box, tiles) then
  begin
    //move back
    _Box.y -= _VelY;
  end;
end;

procedure TDot.Render(var camera: TSDL_Rect);
begin
  //Show the dot
  gDotTexture.Render(_Box.x - camera.x, _Box.y - camera.y);
end;

procedure TDot.SetCamera(var camera: TSDL_Rect);
begin
  //Center the camera over the dot
  camera.x := (mBox.x + DOT_WIDTH div 2) - SCREEN_WIDTH div 2;
  camera.y := (mBox.y + DOT_HEIGHT div 2) - SCREEN_HEIGHT div 2;

  //Keep the camera in bounds
  if camera.x < 0 then
  begin
    camera.x := 0;
  end;
  if camera.y < 0 then
  begin
    camera.y := 0;
  end;
  if camera.x > LEVEL_WIDTH - camera.w then
  begin
    camera.x := LEVEL_WIDTH - camera.w;
  end;
  if camera.y > LEVEL_HEIGHT - camera.h then
  begin
    camera.y := LEVEL_HEIGHT - camera.h;
  end;
end;

procedure TDot.__RenderParticles();
var
  i: integer;
begin
  //Go through particles
  for i := 0 to TOTAL_PARTICLES - 1 do
  begin
    //Delete and replace dead particles
    if _Particles[i].IsDead() then
    begin
      FreeAndNil(_Particles[i]);
      _Particles[i] := TParticle.Create(_PosX, _PosY);
    end;
  end;

  //Show particles
  for i := 0 to TOTAL_PARTICLES - 1 do
    _Particles[i].Render();
end;

end.

