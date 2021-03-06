{ *********************************************************************************** }
{ *                              CryptoLib Library                                  * }
{ *                    Copyright (c) 2018 Ugochukwu Mmaduekwe                       * }
{ *                 Github Repository <https://github.com/Xor-el>                   * }

{ *  Distributed under the MIT software license, see the accompanying file LICENSE  * }
{ *          or visit http://www.opensource.org/licenses/mit-license.php.           * }

{ *                              Acknowledgements:                                  * }
{ *                                                                                 * }
{ *        Thanks to Sphere 10 Software (http://sphere10.com) for sponsoring        * }
{ *                        the development of this library                          * }

{ * ******************************************************************************* * }

(* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& *)

unit ClpDigestRandomGenerator;

{$I ..\..\Include\CryptoLib.inc}

interface

uses
  HlpIHash,
  SyncObjs,
  ClpConverters,
  ClpCryptoLibTypes,
  ClpIDigestRandomGenerator,
  ClpIRandomGenerator;

type
  /// **
  // * Random generation based on the digest with counter. Calling AddSeedMaterial will
  // * always increase the entropy of the hash.
  // * <p>
  // * Internal access to the digest is synchronized so a single one of these can be shared.
  // * </p>
  // */
  TDigestRandomGenerator = class sealed(TInterfacedObject,
    IDigestRandomGenerator, IRandomGenerator)

  strict private
  const
    CYCLE_COUNT = Int64(10);

  var
    FstateCounter, FseedCounter: Int64;
    Fdigest: IHash;
    Fstate, Fseed: TCryptoLibByteArray;

    procedure CycleSeed(); inline;
    procedure GenerateState(); inline;
    procedure DigestAddCounter(seedVal: Int64); inline;
    procedure DigestUpdate(inSeed: TCryptoLibByteArray); inline;
    procedure DigestDoFinal(value: TCryptoLibByteArray); inline;

    class var

      FLock: TCriticalSection;

    class constructor CreateDigestRandomGenerator();
    class destructor DestroyDigestRandomGenerator();

  public

    constructor Create(const digest: IHash);
    procedure AddSeedMaterial(inSeed: TCryptoLibByteArray); overload; inline;
    procedure AddSeedMaterial(rSeed: Int64); overload; inline;
    procedure NextBytes(bytes: TCryptoLibByteArray); overload; inline;
    procedure NextBytes(bytes: TCryptoLibByteArray; start, len: Int32);
      overload;

  end;

implementation

{ TDigestRandomGenerator }

procedure TDigestRandomGenerator.DigestAddCounter(seedVal: Int64);
var
  bytes: TCryptoLibByteArray;
begin
  System.SetLength(bytes, 8);
  bytes := TConverters.ReadUInt64AsBytesLE(UInt64(seedVal));
  Fdigest.TransformBytes(bytes, 0, System.Length(bytes));
end;

procedure TDigestRandomGenerator.DigestUpdate(inSeed: TCryptoLibByteArray);
begin
  Fdigest.TransformBytes(inSeed, 0, System.Length(inSeed));
end;

procedure TDigestRandomGenerator.DigestDoFinal(value: TCryptoLibByteArray);
var
  digest: TCryptoLibByteArray;
begin
  digest := Fdigest.TransformFinal().GetBytes;
  System.Move(digest[0], value[0], System.Length(digest) * System.SizeOf(Byte));
  // value := Fdigest.TransformFinal().GetBytes;
end;

procedure TDigestRandomGenerator.AddSeedMaterial(rSeed: Int64);
begin
  FLock.Acquire;
  try
    DigestAddCounter(rSeed);
    DigestUpdate(Fseed);
    DigestDoFinal(Fseed);
  finally
    FLock.Release;
  end;
end;

procedure TDigestRandomGenerator.AddSeedMaterial(inSeed: TCryptoLibByteArray);
begin
  FLock.Acquire;
  try
    DigestUpdate(inSeed);
    DigestUpdate(Fseed);
    DigestDoFinal(Fseed);
  finally
    FLock.Release;
  end;
end;

constructor TDigestRandomGenerator.Create(const digest: IHash);
begin
  Inherited Create();
  Fdigest := digest;
  System.SetLength(Fseed, digest.HashSize);
  FseedCounter := 1;
  System.SetLength(Fstate, digest.HashSize);
  FstateCounter := 1;
end;

class constructor TDigestRandomGenerator.CreateDigestRandomGenerator;
begin
  FLock := TCriticalSection.Create;
end;

procedure TDigestRandomGenerator.CycleSeed;
begin
  DigestUpdate(Fseed);
  DigestAddCounter(FseedCounter);
  System.Inc(FseedCounter);
  DigestDoFinal(Fseed);
end;

class destructor TDigestRandomGenerator.DestroyDigestRandomGenerator;
begin
  FLock.Free;
end;

procedure TDigestRandomGenerator.GenerateState;
begin
  DigestAddCounter(FstateCounter);
  System.Inc(FstateCounter);
  DigestUpdate(Fstate);
  DigestUpdate(Fseed);
  DigestDoFinal(Fstate);

  if ((FstateCounter mod CYCLE_COUNT) = 0) then
  begin
    CycleSeed();
  end;
end;

procedure TDigestRandomGenerator.NextBytes(bytes: TCryptoLibByteArray);
begin
  NextBytes(bytes, 0, System.Length(bytes));
end;

procedure TDigestRandomGenerator.NextBytes(bytes: TCryptoLibByteArray;
  start, len: Int32);
var
  stateOff, endPoint: Int32;
  I: Integer;
begin
  FLock.Acquire;
  try
    stateOff := 0;
    GenerateState();
    endPoint := start + len;

    for I := start to System.Pred(endPoint) do
    begin
      if (stateOff = System.Length(Fstate)) then
      begin
        GenerateState();
        stateOff := 0;
      end;
      bytes[I] := Fstate[stateOff];
      System.Inc(stateOff);
    end;

  finally
    FLock.Release;
  end;
end;

end.
