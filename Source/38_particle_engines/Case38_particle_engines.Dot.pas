unit Case38_particle_engines.Dot;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  libSDL2,
  Case38_particle_engines.Particle;

type
  TDot = class(TObject)
  public type
    TArr_TParticles = array of TParticle;

  public const
    //The dimensions of the dot
    DOT_WIDTH = 20;
    DOT_HEIGHT = 20;

    //Maximum axis velocity of the dot
    DOT_VEL = 10;

  private
    //The particles
    _Particles: TArr_TParticles;

    //The X and Y offsets of the dot
    _PosX, _PosY: integer;

    //The velocity of the dot
    _VelX, _VelY: integer;

    //Shows the particles
    procedure __RenderParticles();

  public
    constructor Create;
    destructor Destroy; override;

    //Takes key presses and adjusts the dot's velocity
    procedure HandleEvent(var e: TSDL_Event);

    //Moves the dot
    procedure Move();

    //Shows the dot on the screen
    procedure Render();

  end;

implementation

uses
  Case38_particle_engines;

  { TDot }

constructor TDot.Create;
var
  i: integer;
begin
  //Initialize the offsets
  _PosX := 0;
  _PosY := 0;

  //Initialize the velocity
  _VelX := 0;
  _VelY := 0;

  //Initialize particles
  SetLength(_Particles, TOTAL_PARTICLES);
  for i := 0 to TOTAL_PARTICLES - 1 do
    _Particles[i] := TParticle.Create(_PosX, _PosY);
end;

destructor TDot.Destroy;
var
  i: integer;
begin
  for i := 0 to TOTAL_PARTICLES - 1 do
    FreeAndNil(_Particles[i]);

  inherited Destroy;
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

procedure TDot.Move();
begin
  //Move the dot left or right
  _PosX += _VelX;

  //If the dot went too far to the left or right
  if (_PosX < 0) or (_PosX + DOT_WIDTH > SCREEN_WIDTH) then
  begin
    //Move back
    _PosX -= _VelX;
  end;

  //Move the dot up or down
  _PosY += _VelY;

  //If the dot went too far up or down
  if (_PosY < 0) or (_PosY + DOT_HEIGHT > SCREEN_HEIGHT) then
  begin
    //Move back
    _PosY -= _VelY;
  end;
end;

procedure TDot.Render();
begin
  //Show the dot
  gDotTexture.render(_PosX, _PosY);

  //Show particles on top of dot
  __RenderParticles();
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
