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

unit ClpAsn1OutputStream;

{$I ..\Include\CryptoLib.inc}

interface

uses
  Classes,
  ClpIAsn1OutputStream,
  ClpDerOutputStream;

type
  TAsn1OutputStream = class sealed(TDerOutputStream, IAsn1OutputStream)

  public
    constructor Create(os: TStream);

  end;

implementation

{ TAsn1OutputStream }

constructor TAsn1OutputStream.Create(os: TStream);
begin
  Inherited Create(os);
end;

end.
