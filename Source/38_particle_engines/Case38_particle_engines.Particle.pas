unit Case38_particle_engines.Particle;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  Case38_particle_engines.Texture;

type
  TParticle = class(TObject)
  private
    //Offsets
    _PosX, _PosY: integer;

    //Current frame of animation
    _Frame: integer;

    //Type of particle
    _Texture: TTexture;

  public
    constructor Create(x, y: integer);
    destructor Destroy; override;

    //Shows the particle
    procedure Render();

    //Checks if particle is dead
    function IsDead(): boolean;
  end;

implementation

uses
  Case38_particle_engines;

  { TParticle }

constructor TParticle.Create(x, y: integer);
var
  max: smallint;
begin
  Randomize;

  max := smallint.MaxValue;

  //Set offsets
  _PosX := x - 5 + (Random(max) mod 25);
  _PosY := y - 5 + (Random(max) mod 25);

  //Initialize animation
  _Frame := Random(max) mod 5;

  //Set type
  case Random(max) mod 3 of
    0: _Texture := gRedTexture;
    1: _Texture := gGreenTexture;
    2: _Texture := gBlueTexture;
  end;
end;

destructor TParticle.Destroy;
begin
  inherited Destroy;
end;

function TParticle.IsDead(): boolean;
begin
  Result := _Frame > 10;
end;

procedure TParticle.Render();
begin
  //Show image
  _Texture.Render(_PosX, _PosY);

  //Show shimmer
  if _Frame mod 2 = 0 then
    gShimmerTexture.Render(_PosX, _PosY);

  //Animate
  _Frame += 1;
end;

end.
