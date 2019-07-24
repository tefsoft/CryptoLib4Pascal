{ *********************************************************************************** }
{ *                              CryptoLib Library                                  * }
{ *                Copyright (c) 2018 - 20XX Ugochukwu Mmaduekwe                    * }
{ *                 Github Repository <https://github.com/Xor-el>                   * }

{ *  Distributed under the MIT software license, see the accompanying file LICENSE  * }
{ *          or visit http://www.opensource.org/licenses/mit-license.php.           * }

{ *                              Acknowledgements:                                  * }
{ *                                                                                 * }
{ *      Thanks to Sphere 10 Software (http://www.sphere10.com/) for sponsoring     * }
{ *                           development of this library                           * }

{ * ******************************************************************************* * }

(* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& *)

unit ClpECAlgorithms;

{$I ..\..\Include\CryptoLib.inc}

interface

uses
  SysUtils,
  Math,
  ClpCryptoLibTypes,
  ClpBits,
  ClpNat,
  ClpBigInteger,
  ClpWNafPreCompInfo,
  ClpIPolynomialExtensionField,
  ClpIMultipliers,
  ClpIGlvEndomorphism,
  ClpIWNafPreCompInfo,
  ClpIScalarSplitParameters,
  ClpIPreCompInfo,
  ClpIEndoPreCompInfo,
  ClpEndoPreCompInfo,
  ClpIPreCompCallBack,
  ClpFixedPointPreCompInfo,
  ClpIFixedPointPreCompInfo,
  ClpIECC,
  ClpECCurveConstants,
  ClpIFiniteField;

resourcestring
  SInvalidArray =
    'Point and Scalar Arrays Should be Non-Null, and of Equal, Non-Zero, Length';
  SInvalidPointLocation = 'Point Must be on the Same Curve';
  SInvalidPoint = 'Invalid Point, "P"';
  SInvalidResult = 'Invalid Result';
  SInvalidRange = 'Must be in the Range [2, 16], "width"';
  SInvalidRange2 = 'Must be in the Range [2, 8], "width"';
  SInvalidComputation =
    'Fixed-Point Comb Doesn''t Support Scalars Larger Than The Curve Order';

type
  TWNafUtilities = class abstract(TObject)

  strict private
  const
    DEFAULT_WINDOW_SIZE_CUTOFFS: array [0 .. 5] of Int32 = (13, 41, 121, 337,
      897, 2305);

    MAX_WIDTH = Int32(16);

  class var
    FEMPTY_BYTES: TCryptoLibByteArray;
    FEMPTY_INTS: TCryptoLibInt32Array;

  type
    IMapPointCallback = interface(IPreCompCallback)
      ['{730BF27F-D5C3-4DF4-AC77-B8653C457C10}']

    end;

  type
    TMapPointCallback = class(TInterfacedObject, IPreCompCallback,
      IMapPointCallback)

    strict private
    var
      Fm_wnafPreCompP: IWNafPreCompInfo;
      Fm_includeNegated: Boolean;
      Fm_pointMap: IECPointMap;

    public
      constructor Create(const wnafPreCompP: IWNafPreCompInfo;
        includeNegated: Boolean; const pointMap: IECPointMap);

      function Precompute(const existing: IPreCompInfo): IPreCompInfo;

    end;

  type
    IWNafCallback = interface(IPreCompCallback)
      ['{A439A606-7899-4720-937E-C2F3D94D4811}']

    end;

  type
    TWNafCallback = class(TInterfacedObject, IPreCompCallback, IWNafCallback)

    strict private

    var
      Fm_p: IECPoint;
      FminWidth: Int32;
      Fm_includeNegated: Boolean;

      class function CheckExisting(const existingWNaf: IWNafPreCompInfo;
        width, reqPreCompLen: Int32; includeNegated: Boolean): Boolean;
        static; inline;

      class function CheckTable(const table: TCryptoLibGenericArray<IECPoint>;
        reqLen: Int32): Boolean; static; inline;

    public
      constructor Create(const p: IECPoint; minWidth: Int32;
        includeNegated: Boolean);

      function Precompute(const existing: IPreCompInfo): IPreCompInfo;

    end;

  type
    IPointMapCallback = interface(IPreCompCallback)
      ['{00A66D4E-7D61-4A47-AE36-E8D89DEE8D9F}']

    end;

  type
    TPointMapCallback = class(TInterfacedObject, IPreCompCallback,
      IPointMapCallback)

    strict private

    var
      Fm_p: IECPoint;
      FpointMap: IECPointMap;
      FfromWNaf: IWNafPreCompInfo;
      FIncludeNegated: Boolean;

      class function CheckExisting(const existingWNaf: IWNafPreCompInfo;
        width, reqPreCompLen: Int32; includeNegated: Boolean): Boolean;
        static; inline;

      class function CheckTable(const table: TCryptoLibGenericArray<IECPoint>;
        reqLen: Int32): Boolean; static; inline;

    public
      constructor Create(const p: IECPoint; const pointMap: IECPointMap;
        const fromWNaf: IWNafPreCompInfo; includeNegated: Boolean);

      function Precompute(const existing: IPreCompInfo): IPreCompInfo;

    end;

  type
    IBasePointCallback = interface(IPreCompCallback)
      ['{5A81CB00-3CB4-474D-A2A7-E949F7E71AEC}']

    end;

  type
    TBasePointCallback = class(TInterfacedObject, IPreCompCallback,
      IBasePointCallback)

    strict private
    var
      FConfWidth: Int32;

    public
      constructor Create(ConfWidth: Int32);

      function Precompute(const existing: IPreCompInfo): IPreCompInfo;

    end;

  class function Trim(const a: TCryptoLibByteArray; length: Int32)
    : TCryptoLibByteArray; overload; static; inline;

  class function Trim(const a: TCryptoLibInt32Array; length: Int32)
    : TCryptoLibInt32Array; overload; static; inline;

  class function ResizeTable(const a: TCryptoLibGenericArray<IECPoint>;
    length: Int32): TCryptoLibGenericArray<IECPoint>; static; inline;

  class procedure Boot(); static;
  class constructor CreateWNafUtilities();

  public

    const
    PRECOMP_NAME: String = 'bc_wnaf';

    class function GenerateCompactNaf(const k: TBigInteger)
      : TCryptoLibInt32Array; static;
    class function GenerateCompactWindowNaf(width: Int32; const k: TBigInteger)
      : TCryptoLibInt32Array; static;

    class function GenerateJsf(const g, h: TBigInteger)
      : TCryptoLibByteArray; static;
    class function GenerateNaf(const k: TBigInteger)
      : TCryptoLibByteArray; static;
    // /**
    // * Computes the Window NAF (non-adjacent Form) of an integer.
    // * @param width The width <code>w</code> of the Window NAF. The width is
    // * defined as the minimal number <code>w</code>, such that for any
    // * <code>w</code> consecutive digits in the resulting representation, at
    // * most one is non-zero.
    // * @param k The integer of which the Window NAF is computed.
    // * @return The Window NAF of the given width, such that the following holds:
    // * <code>k = &amp;sum;<sub>i=0</sub><sup>l-1</sup> k<sub>i</sub>2<sup>i</sup>
    // * </code>, where the <code>k<sub>i</sub></code> denote the elements of the
    // * returned <code>byte[]</code>.
    // */
    class function GenerateWindowNaf(width: Int32; const k: TBigInteger)
      : TCryptoLibByteArray; static;

    class function GetNafWeight(const k: TBigInteger): Int32; static; inline;

    class function GetWNafPreCompInfo(const p: IECPoint): IWNafPreCompInfo;
      overload; static; inline;

    class function GetWNafPreCompInfo(const preCompInfo: IPreCompInfo)
      : IWNafPreCompInfo; overload; static; inline;

    /// <summary>
    /// Determine window width to use for a scalar multiplication of the
    /// given size.
    /// </summary>
    /// <param name="bits">
    /// the bit-length of the scalar to multiply by
    /// </param>
    /// <returns>
    /// the window size to use
    /// </returns>
    class function GetWindowSize(bits: Int32): Int32; overload; static; inline;

    /// <summary>
    /// Determine window width to use for a scalar multiplication of the
    /// given size.
    /// </summary>
    /// <param name="bits">
    /// the bit-length of the scalar to multiply by
    /// </param>
    /// <param name="maxWidth">
    /// the maximum window width to return
    /// </param>
    /// <returns>
    /// the window size to use
    /// </returns>
    class function GetWindowSize(bits, maxWidth: Int32): Int32; overload;
      static; inline;

    /// <summary>
    /// Determine window width to use for a scalar multiplication of the
    /// given size.
    /// </summary>
    /// <param name="bits">
    /// the bit-length of the scalar to multiply by
    /// </param>
    /// <param name="windowSizeCutoffs">
    /// a monotonically increasing list of bit sizes at which to increment
    /// the window width
    /// </param>
    /// <returns>
    /// the window size to use
    /// </returns>
    class function GetWindowSize(bits: Int32;
      const windowSizeCutoffs: array of Int32): Int32; overload; static;

    /// <summary>
    /// Determine window width to use for a scalar multiplication of the
    /// given size.
    /// </summary>
    /// <param name="bits">
    /// the bit-length of the scalar to multiply by
    /// </param>
    /// <param name="windowSizeCutoffs">
    /// a monotonically increasing list of bit sizes at which to increment
    /// the window width
    /// </param>
    /// /// <param name="maxWidth">
    /// the maximum window width to return
    /// </param>
    /// <returns>
    /// the window size to use
    /// </returns>
    class function GetWindowSize(bits: Int32;
      const windowSizeCutoffs: array of Int32; maxWidth: Int32): Int32;
      overload; static;

    class function Precompute(const p: IECPoint; minWidth: Int32;
      includeNegated: Boolean): IWNafPreCompInfo; static;

    class procedure ConfigureBasepoint(const p: IECPoint); static;

    class function PrecomputeWithPointMap(const p: IECPoint;
      const pointMap: IECPointMap; const fromWNaf: IWNafPreCompInfo;
      includeNegated: Boolean): IWNafPreCompInfo;

  end;

type
  TEndoUtilities = class abstract(TObject)

  strict private
  type
    IEndoCallback = interface(IPreCompCallback)
      ['{80C0B850-A97A-4603-A42F-A476ABAF2026}']

    end;

  type
    TEndoCallback = class(TInterfacedObject, IPreCompCallback, IEndoCallback)

    strict private
    var
      Fendomorphism: IECEndomorphism;
      Fp: IECPoint;

      class function CheckExisting(const existingEndo: IEndoPreCompInfo;
        const endomorphism: IECEndomorphism): Boolean; static; inline;

    public
      constructor Create(const endomorphism: IECEndomorphism;
        const p: IECPoint);

      function Precompute(const existing: IPreCompInfo): IPreCompInfo;

    end;

  class function CalculateB(const k, g: TBigInteger; t: Int32)
    : TBigInteger; static;

  public

    const
    PRECOMP_NAME: String = 'bc_endo';

  public
    class function MapPoint(const endomorphism: IECEndomorphism;
      const p: IECPoint): IECPoint; static;

    class function DecomposeScalar(const p: IScalarSplitParameters;
      const k: TBigInteger): TCryptoLibGenericArray<TBigInteger>; static;

  end;

type
  TFixedPointUtilities = class sealed(TObject)
  strict private

  type
    IFixedPointCallback = interface(IPreCompCallback)
      ['{E6DFE8D3-A890-4568-AA4A-3D8BC6AF16E9}']

    end;

  type
    TFixedPointCallback = class(TInterfacedObject, IPreCompCallback,
      IFixedPointCallback)

    strict private
    var
      Fm_p: IECPoint;

      class function CheckExisting(const existingFP: IFixedPointPreCompInfo;
        n: Int32): Boolean; static; inline;

      class function CheckTable(const table: IECLookupTable; n: Int32): Boolean;
        static; inline;

    public
      constructor Create(const p: IECPoint);

      function Precompute(const existing: IPreCompInfo): IPreCompInfo;

    end;

  const
    PRECOMP_NAME: String = 'bc_fixed_point';

  public

    class function GetFixedPointPreCompInfo(const preCompInfo: IPreCompInfo)
      : IFixedPointPreCompInfo; static; inline;

    class function GetCombSize(const c: IECCurve): Int32; static; inline;

    class function Precompute(const p: IECPoint)
      : IFixedPointPreCompInfo; static;
  end;

type
  TECAlgorithms = class sealed(TObject)

  strict private
    class function ImplShamirsTrickWNaf(const preCompP,
      preCompNegP: TCryptoLibGenericArray<IECPoint>;
      const wnafP: TCryptoLibByteArray;
      const preCompQ, preCompNegQ: TCryptoLibGenericArray<IECPoint>;
      const wnafQ: TCryptoLibByteArray): IECPoint; overload; static;

    class function ImplSumOfMultiplies(const negs: TCryptoLibBooleanArray;
      const infos: TCryptoLibGenericArray<IWNafPreCompInfo>;
      const wnafs: TCryptoLibMatrixByteArray): IECPoint; overload; static;

    class function ImplShamirsTrickFixedPoint(const p: IECPoint;
      const k: TBigInteger; const q: IECPoint; const l: TBigInteger)
      : IECPoint; static;

  public
    class function IsF2mCurve(const c: IECCurve): Boolean; static;
    class function IsF2mField(const field: IFiniteField): Boolean; static;
    class function IsFpCurve(const c: IECCurve): Boolean; static;
    class function IsFpField(const field: IFiniteField): Boolean; static;

    class function SumOfMultiplies(const ps: TCryptoLibGenericArray<IECPoint>;
      const ks: TCryptoLibGenericArray<TBigInteger>): IECPoint; static;

    class function SumOfTwoMultiplies(const p: IECPoint; const a: TBigInteger;
      const q: IECPoint; const b: TBigInteger): IECPoint; static;

    // /*
    // * "Shamir's Trick", originally due to E. G. Straus
    // * (Addition chains of vectors. American Mathematical Monthly,
    // * 71(7):806-808, Aug./Sept. 1964)
    // *
    // * Input: The points P, Q, scalar k = (km?, ... , k1, k0)
    // * and scalar l = (lm?, ... , l1, l0).
    // * Output: R = k * P + l * Q.
    // * 1: Z <- P + Q
    // * 2: R <- O
    // * 3: for i from m-1 down to 0 do
    // * 4:        R <- R + R        {point doubling}
    // * 5:        if (ki = 1) and (li = 0) then R <- R + P end if
    // * 6:        if (ki = 0) and (li = 1) then R <- R + Q end if
    // * 7:        if (ki = 1) and (li = 1) then R <- R + Z end if
    // * 8: end for
    // * 9: return R
    // */
    class function ShamirsTrick(const p: IECPoint; const k: TBigInteger;
      const q: IECPoint; const l: TBigInteger): IECPoint; static;

    class function ImportPoint(const c: IECCurve; const p: IECPoint)
      : IECPoint; static;

    class procedure MontgomeryTrick(const zs
      : TCryptoLibGenericArray<IECFieldElement>; off, len: Int32); overload;
      static; inline;

    class procedure MontgomeryTrick(const zs
      : TCryptoLibGenericArray<IECFieldElement>; off, len: Int32;
      const scale: IECFieldElement); overload; static;

    // /**
    // * Simple shift-and-add multiplication. Serves as reference implementation
    // * to verify (possibly faster) implementations, and for very small scalars.
    // *
    // * @param p
    // *            The point to multiply.
    // * @param k
    // *            The multiplier.
    // * @return The result of the point multiplication <code>kP</code>.
    // */
    class function ReferenceMultiply(const p: IECPoint; const k: TBigInteger)
      : IECPoint; static;

    class function ImplCheckResult(const p: IECPoint): IECPoint; static;

    class function ValidatePoint(const p: IECPoint): IECPoint; static;

    class function CleanPoint(const c: IECCurve; const p: IECPoint)
      : IECPoint; static;

    class function ImplShamirsTrickJsf(const p: IECPoint; const k: TBigInteger;
      const q: IECPoint; const l: TBigInteger): IECPoint; static;

    class function ImplShamirsTrickWNaf(const p: IECPoint; const k: TBigInteger;
      const q: IECPoint; const l: TBigInteger): IECPoint; overload; static;

    class function ImplShamirsTrickWNaf(const endomorphism: IECEndomorphism;
      const p: IECPoint; const k, l: TBigInteger): IECPoint; overload; static;

    class function ImplSumOfMultiplies
      (const ps: TCryptoLibGenericArray<IECPoint>;
      const ks: TCryptoLibGenericArray<TBigInteger>): IECPoint;
      overload; static;

    class function ImplSumOfMultipliesGlv
      (const ps: TCryptoLibGenericArray<IECPoint>;
      const ks: TCryptoLibGenericArray<TBigInteger>;
      const glvEndomorphism: IGlvEndomorphism): IECPoint; static;

    class function ImplSumOfMultiplies(const endomorphism: IECEndomorphism;
      const ps: TCryptoLibGenericArray<IECPoint>;
      const ks: TCryptoLibGenericArray<TBigInteger>): IECPoint;
      overload; static;

  end;

implementation

uses
  ClpMultipliers; // included here to avoid circular dependency :)

{ TECAlgorithms }

class function TECAlgorithms.ImplCheckResult(const p: IECPoint): IECPoint;
begin
  if (not(p.IsValidPartial())) then
  begin
    raise EArgumentCryptoLibException.CreateRes(@SInvalidResult);
  end;

  result := p;
end;

class function TECAlgorithms.CleanPoint(const c: IECCurve; const p: IECPoint)
  : IECPoint;
var
  cp: IECCurve;
begin
  cp := p.Curve;
  if (not c.Equals(cp)) then
  begin
    raise EArgumentCryptoLibException.CreateRes(@SInvalidPointLocation);
  end;

  result := c.DecodePoint(p.getEncoded(false));
end;

class function TECAlgorithms.ValidatePoint(const p: IECPoint): IECPoint;
begin
  if (not p.IsValid()) then
  begin
    raise EArgumentCryptoLibException.CreateRes(@SInvalidPoint);
  end;

  result := p;
end;

class function TECAlgorithms.ImplShamirsTrickFixedPoint(const p: IECPoint;
  const k: TBigInteger; const q: IECPoint; const l: TBigInteger): IECPoint;
var
  c: IECCurve;
  combSize, widthP, widthQ, width, d, fullComb, i, top, j: Int32;
  infoP, infoQ: IFixedPointPreCompInfo;
  lookupTableP, lookupTableQ: IECLookupTable;
  m: IFixedPointCombMultiplier;
  r1, r2, R, addP, addQ, t: IECPoint;
  BigK, BigL: TCryptoLibUInt32Array;
  secretBitK, secretBitL, secretIndexK, secretIndexL: UInt32;
begin
  c := p.Curve;
  combSize := TFixedPointUtilities.GetCombSize(c);

  if (((k.BitLength) > combSize) or (l.BitLength > combSize)) then
  begin
    (*
      * TODO The comb works best when the scalars are less than the (possibly unknown) order.
      * Still, if we want to handle larger scalars, we could allow customization of the comb
      * size, or alternatively we could deal with the 'extra' bits either by running the comb
      * multiple times as necessary, or by using an alternative multiplier as prelude.
    *)
    raise EInvalidOperationCryptoLibException.CreateRes(@SInvalidComputation);
  end;

  infoP := TFixedPointUtilities.Precompute(p);
  infoQ := TFixedPointUtilities.Precompute(q);

  lookupTableP := infoP.LookupTable;
  lookupTableQ := infoQ.LookupTable;

  widthP := infoP.width;
  widthQ := infoQ.width;

  // TODO This shouldn't normally happen, but a better "solution" is desirable anyway
  if (widthP <> widthQ) then
  begin
    m := TFixedPointCombMultiplier.Create();
    r1 := m.Multiply(p, k);
    r2 := m.Multiply(q, l);
    result := r1.Add(r2);
    Exit;
  end;

  width := widthP;

  d := ((combSize + width) - 1) div width;

  R := c.Infinity;

  fullComb := d * width;
  BigK := TNat.FromBigInteger(fullComb, k);
  BigL := TNat.FromBigInteger(fullComb, l);

  top := fullComb - 1;

  for i := 0 to System.Pred(d) do
  begin
    secretIndexK := 0;
    secretIndexL := 0;

    j := top - i;

    while j >= 0 do
    begin

      secretBitK := BigK[TBits.Asr32(j, 5)] shr (j and $1F);
      secretIndexK := secretIndexK xor (secretBitK shr 1);
      secretIndexK := secretIndexK shl 1;
      secretIndexK := secretIndexK xor secretBitK;

      secretBitL := BigL[TBits.Asr32(j, 5)] shr (j and $1F);
      secretIndexL := secretIndexL xor (secretBitL shr 1);
      secretIndexL := secretIndexL shl 1;
      secretIndexL := secretIndexL xor secretBitL;

      System.Dec(j, d);
    end;

    addP := lookupTableP.Lookup(Int32(secretIndexK));
    addQ := lookupTableQ.Lookup(Int32(secretIndexL));

    t := addP.Add(addQ);

    R := R.TwicePlus(t);
  end;

  result := R.Add(infoP.Offset).Add(infoQ.Offset);
end;

class function TECAlgorithms.ImplShamirsTrickJsf(const p: IECPoint;
  const k: TBigInteger; const q: IECPoint; const l: TBigInteger): IECPoint;
var
  Curve: IECCurve;
  Infinity, R: IECPoint;
  PaddQ, PsubQ: IECPoint;
  points, table: TCryptoLibGenericArray<IECPoint>;
  jsf: TCryptoLibByteArray;
  i, jsfi, kDigit, lDigit, index: Int32;
begin
  Curve := p.Curve;
  Infinity := Curve.Infinity;

  // TODO conjugate co-Z addition (ZADDC) can return both of these
  PaddQ := p.Add(q);
  PsubQ := p.Subtract(q);

  points := TCryptoLibGenericArray<IECPoint>.Create(q, PsubQ, p, PaddQ);
  Curve.NormalizeAll(points);

  table := TCryptoLibGenericArray<IECPoint>.Create(points[3].Negate(),
    points[2].Negate(), points[1].Negate(), points[0].Negate(), Infinity,
    points[0], points[1], points[2], points[3]);

  jsf := TWNafUtilities.GenerateJsf(k, l);

  R := Infinity;

  i := System.length(jsf);
  System.Dec(i);
  while (i >= 0) do
  begin
    jsfi := jsf[i];

    // NOTE: The shifting ensures the sign is extended correctly
    kDigit := (TBits.Asr32((jsfi shl 24), 28));
    lDigit := (TBits.Asr32((jsfi shl 28), 28));

    index := 4 + (kDigit * 3) + lDigit;
    R := R.TwicePlus(table[index]);
    System.Dec(i);
  end;

  result := R;
end;

class function TECAlgorithms.ImplShamirsTrickWNaf(const endomorphism
  : IECEndomorphism; const p: IECPoint; const k, l: TBigInteger): IECPoint;
var
  negK, negL: Boolean;
  minWidth, widthP, widthQ: Int32;
  q: IECPoint;
  infoP, infoQ: IWNafPreCompInfo;
  preCompP, preCompQ, preCompNegP, preCompNegQ
    : TCryptoLibGenericArray<IECPoint>;
  wnafP, wnafQ: TCryptoLibByteArray;
  LK, LL: TBigInteger;
begin
  LK := k;
  LL := l;
  negK := LK.SignValue < 0;
  negL := LL.SignValue < 0;

  LK := LK.Abs();
  LL := LL.Abs();

  minWidth := TWNafUtilities.GetWindowSize(Max(k.BitLength, l.BitLength), 8);

  infoP := TWNafUtilities.Precompute(p, minWidth, true);
  q := TEndoUtilities.MapPoint(endomorphism, p);
  infoQ := TWNafUtilities.PrecomputeWithPointMap(q, endomorphism.pointMap,
    infoP, true);

  widthP := Min(8, infoP.width);
  widthQ := Min(8, infoQ.width);

  case negK of
    true:
      preCompP := infoP.PreCompNeg;
    false:
      preCompP := infoP.PreComp;
  end;

  case negL of
    true:
      preCompQ := infoQ.PreCompNeg;
    false:
      preCompQ := infoQ.PreComp
  end;

  case negK of
    true:
      preCompNegP := infoP.PreComp;
    false:
      preCompNegP := infoP.PreCompNeg;
  end;

  case negL of
    true:
      preCompNegQ := infoQ.PreComp;
    false:
      preCompNegQ := infoQ.PreCompNeg
  end;

  wnafP := TWNafUtilities.GenerateWindowNaf(widthP, LK);
  wnafQ := TWNafUtilities.GenerateWindowNaf(widthQ, LL);

  result := ImplShamirsTrickWNaf(preCompP, preCompNegP, wnafP, preCompQ,
    preCompNegQ, wnafQ);

  infoP.PreComp := Nil; // Review
  infoP.PreCompNeg := Nil; // Review
  infoQ.PreComp := Nil; // Review
  infoQ.PreCompNeg := Nil; // Review

end;

class function TECAlgorithms.ImplShamirsTrickWNaf(const p: IECPoint;
  const k: TBigInteger; const q: IECPoint; const l: TBigInteger): IECPoint;
var
  negK, negL: Boolean;
  minWidthP, minWidthQ, widthP, widthQ, combSize: Int32;
  infoP, infoQ: IWNafPreCompInfo;
  preCompP, preCompQ, preCompNegP, preCompNegQ
    : TCryptoLibGenericArray<IECPoint>;
  wnafP, wnafQ: TCryptoLibByteArray;
  kAbs, lAbs: TBigInteger;
  c: IECCurve;
begin

  negK := k.SignValue < 0;
  negL := l.SignValue < 0;

  kAbs := k.Abs();
  lAbs := l.Abs();

  minWidthP := TWNafUtilities.GetWindowSize(kAbs.BitLength, 8);
  minWidthQ := TWNafUtilities.GetWindowSize(lAbs.BitLength, 8);

  infoP := TWNafUtilities.Precompute(p, minWidthP, true);
  infoQ := TWNafUtilities.Precompute(q, minWidthQ, true);

  // When P, Q are 'promoted' (i.e. reused several times), switch to fixed-point algorithm

  c := p.Curve;
  combSize := TFixedPointUtilities.GetCombSize(c);
  if ((not negK) and (not negL) and (k.BitLength <= combSize) and
    (l.BitLength <= combSize) and (infoP.IsPromoted) and (infoQ.IsPromoted))
  then
  begin
    result := ImplShamirsTrickFixedPoint(p, k, q, l);
    Exit;
  end;

  widthP := Min(8, infoP.width);
  widthQ := Min(8, infoQ.width);

  if negK then
  begin
    preCompP := infoP.PreCompNeg
  end
  else
  begin
    preCompP := infoP.PreComp
  end;

  if negL then
  begin
    preCompQ := infoQ.PreCompNeg
  end
  else
  begin
    preCompQ := infoQ.PreComp
  end;

  if negK then
  begin
    preCompNegP := infoP.PreComp
  end
  else
  begin
    preCompNegP := infoP.PreCompNeg
  end;

  if negL then
  begin
    preCompNegQ := infoQ.PreComp
  end
  else
  begin
    preCompNegQ := infoQ.PreCompNeg
  end;

  wnafP := TWNafUtilities.GenerateWindowNaf(widthP, kAbs);
  wnafQ := TWNafUtilities.GenerateWindowNaf(widthQ, lAbs);

  result := ImplShamirsTrickWNaf(preCompP, preCompNegP, wnafP, preCompQ,
    preCompNegQ, wnafQ);
  infoP.PreComp := Nil; // Review
  infoP.PreCompNeg := Nil; // Review
  infoQ.PreComp := Nil; // Review
  infoQ.PreCompNeg := Nil; // Review
end;

class function TECAlgorithms.ImplShamirsTrickWNaf(const preCompP,
  preCompNegP: TCryptoLibGenericArray<IECPoint>;
  const wnafP: TCryptoLibByteArray;
  const preCompQ, preCompNegQ: TCryptoLibGenericArray<IECPoint>;
  const wnafQ: TCryptoLibByteArray): IECPoint;
var
  len, zeroes, i, wiP, wiQ, nP, nQ: Int32;
  Curve: IECCurve;
  Infinity, R, point: IECPoint;
  tableP, tableQ: TCryptoLibGenericArray<IECPoint>;
begin
  len := Max(System.length(wnafP), System.length(wnafQ));

  Curve := preCompP[0].Curve;
  Infinity := Curve.Infinity;

  R := Infinity;
  zeroes := 0;

  i := len - 1;
  while (i >= 0) do
  begin

    if i < System.length(wnafP) then
    begin
      wiP := Int32(ShortInt(wnafP[i]));
    end
    else
    begin
      wiP := 0;
    end;

    if i < System.length(wnafQ) then
    begin
      wiQ := Int32(ShortInt(wnafQ[i]));
    end
    else
    begin
      wiQ := 0;
    end;

    if ((wiP or wiQ) = 0) then
    begin
      System.Inc(zeroes);
      System.Dec(i);
      continue;
    end;

    point := Infinity;
    if (wiP <> 0) then
    begin
      nP := System.Abs(wiP);
      if wiP < 0 then
      begin
        tableP := preCompNegP;
      end
      else
      begin
        tableP := preCompP;
      end;

      point := point.Add(tableP[TBits.Asr32(nP, 1)]);
    end;
    if (wiQ <> 0) then
    begin

      nQ := System.Abs(wiQ);
      if wiQ < 0 then
      begin
        tableQ := preCompNegQ;
      end
      else
      begin
        tableQ := preCompQ;
      end;

      point := point.Add(tableQ[TBits.Asr32(nQ, 1)]);

    end;

    if (zeroes > 0) then
    begin
      R := R.TimesPow2(zeroes);
      zeroes := 0;
    end;

    R := R.TwicePlus(point);
    System.Dec(i);
  end;

  if (zeroes > 0) then
  begin
    R := R.TimesPow2(zeroes);
  end;

  result := R;
end;

class function TECAlgorithms.ImplSumOfMultiplies(const endomorphism
  : IECEndomorphism; const ps: TCryptoLibGenericArray<IECPoint>;
  const ks: TCryptoLibGenericArray<TBigInteger>): IECPoint;
var
  halfCount, fullCount: Int32;
  negs: TCryptoLibBooleanArray;
  infos: TCryptoLibGenericArray<IWNafPreCompInfo>;
  infoP, infoQ: IWNafPreCompInfo;
  wnafs: TCryptoLibMatrixByteArray;
  i, j0, j1, minWidth, widthP, widthQ: Int32;
  kj0, kj1: TBigInteger;
  p, q: IECPoint;
  pointMap: IECPointMap;
begin
  halfCount := System.length(ps);
  fullCount := halfCount shl 1;
  System.SetLength(negs, fullCount);
  System.SetLength(infos, fullCount);
  System.SetLength(wnafs, fullCount);

  pointMap := endomorphism.pointMap;

  for i := 0 to System.Pred(halfCount) do
  begin
    j0 := i shl 1;
    j1 := j0 + 1;

    kj0 := ks[j0];
    negs[j0] := kj0.SignValue < 0;
    kj0 := kj0.Abs();
    kj1 := ks[j1];
    negs[j1] := kj1.SignValue < 0;
    kj1 := kj1.Abs();

    minWidth := TWNafUtilities.GetWindowSize
      (Max(kj0.BitLength, kj1.BitLength), 8);

    p := ps[i];
    infoP := TWNafUtilities.Precompute(p, minWidth, true);
    q := TEndoUtilities.MapPoint(endomorphism, p);
    infoQ := TWNafUtilities.PrecomputeWithPointMap(q, pointMap, infoP, true);

    widthP := Min(8, infoP.width);
    widthQ := Min(8, infoQ.width);

    infos[j0] := infoP;
    infos[j1] := infoQ;
    wnafs[j0] := TWNafUtilities.GenerateWindowNaf(widthP, kj0);
    wnafs[j1] := TWNafUtilities.GenerateWindowNaf(widthQ, kj1);
  end;

  result := ImplSumOfMultiplies(negs, infos, wnafs);

  for i := System.Low(infos) to System.High(infos) do
  begin
    infos[i].PreComp := Nil; // Review
    infos[i].PreCompNeg := Nil; // Review
  end;

end;

class function TECAlgorithms.ImplSumOfMultiplies
  (const ps: TCryptoLibGenericArray<IECPoint>;
  const ks: TCryptoLibGenericArray<TBigInteger>): IECPoint;
var
  count, i, width, minWidth: Int32;
  negs: TCryptoLibBooleanArray;
  info: IWNafPreCompInfo;
  infos: TCryptoLibGenericArray<IWNafPreCompInfo>;
  wnafs: TCryptoLibMatrixByteArray;
  ki: TBigInteger;
begin
  count := System.length(ps);
  System.SetLength(negs, count);

  System.SetLength(infos, count);

  System.SetLength(wnafs, count);

  for i := 0 to System.Pred(count) do
  begin
    ki := ks[i];
    negs[i] := ki.SignValue < 0;
    ki := ki.Abs();

    minWidth := TWNafUtilities.GetWindowSize(ki.BitLength, 8);
    info := TWNafUtilities.Precompute(ps[i], minWidth, true);
    width := Min(8, info.width);

    infos[i] := info;
    wnafs[i] := TWNafUtilities.GenerateWindowNaf(width, ki);
  end;

  result := ImplSumOfMultiplies(negs, infos, wnafs);

  for i := System.Low(infos) to System.High(infos) do
  begin
    infos[i].PreComp := Nil; // Review
    infos[i].PreCompNeg := Nil; // Review
  end;

end;

class function TECAlgorithms.ImplSumOfMultiplies
  (const negs: TCryptoLibBooleanArray;
  const infos: TCryptoLibGenericArray<IWNafPreCompInfo>;
  const wnafs: TCryptoLibMatrixByteArray): IECPoint;
var
  len, count, zeroes: Int32;
  i, j, wi, n: Int32;
  Curve: IECCurve;
  Infinity, R, point: IECPoint;
  wnaf: TCryptoLibByteArray;
  info: IWNafPreCompInfo;
  table: TCryptoLibGenericArray<IECPoint>;
begin
  len := 0;
  count := System.length(wnafs);

  for i := 0 to System.Pred(count) do
  begin
    len := Max(len, System.length(wnafs[i]));
  end;

  Curve := infos[0].PreComp[0].Curve;
  Infinity := Curve.Infinity;

  R := Infinity;
  zeroes := 0;

  i := len - 1;
  while (i >= 0) do
  begin
    point := Infinity;

    for j := 0 to System.Pred(count) do
    begin
      wnaf := wnafs[j];
      if i < System.length(wnaf) then
      begin
        wi := Int32(ShortInt(wnaf[i]));
      end
      else
      begin
        wi := 0;
      end;

      if (wi <> 0) then
      begin
        n := System.Abs(wi);
        info := infos[j];
        if (wi < 0 = negs[j]) then
        begin
          table := info.PreComp;
        end
        else
        begin
          table := info.PreCompNeg;
        end;

        point := point.Add(table[TBits.Asr32(n, 1)]);
      end;
    end;

    if (point = Infinity) then
    begin
      System.Inc(zeroes);
      System.Dec(i);
      continue;
    end;

    if (zeroes > 0) then
    begin
      R := R.TimesPow2(zeroes);
      zeroes := 0;
    end;

    R := R.TwicePlus(point);

    System.Dec(i);
  end;

  if (zeroes > 0) then
  begin
    R := R.TimesPow2(zeroes);
  end;

  result := R;

end;

class function TECAlgorithms.ImplSumOfMultipliesGlv
  (const ps: TCryptoLibGenericArray<IECPoint>;
  const ks: TCryptoLibGenericArray<TBigInteger>;
  const glvEndomorphism: IGlvEndomorphism): IECPoint;
var
  n: TBigInteger;
  len, i, j: Int32;
  &abs, ab: TCryptoLibGenericArray<TBigInteger>;
  pqs: TCryptoLibGenericArray<IECPoint>;
  p, q: IECPoint;
begin
  n := ps[0].Curve.Order;

  len := System.length(ps);

  System.SetLength(Abs, len shl 1);

  i := 0;
  j := 0;

  while (i < len) do
  begin
    ab := glvEndomorphism.DecomposeScalar(ks[i].&Mod(n));

    Abs[j] := ab[0];
    System.Inc(j);
    Abs[j] := ab[1];
    System.Inc(j);
    System.Inc(i);
  end;

  if (glvEndomorphism.HasEfficientPointMap) then
  begin
    result := TECAlgorithms.ImplSumOfMultiplies(glvEndomorphism, ps, Abs);
    Exit;
  end;

  System.SetLength(pqs, len shl 1);

  i := 0;
  j := 0;

  while (i < len) do
  begin
    p := ps[i];
    q := TEndoUtilities.MapPoint(glvEndomorphism, p);

    pqs[j] := p;
    System.Inc(j);
    pqs[j] := q;
    System.Inc(j);
    System.Inc(i);
  end;

  result := TECAlgorithms.ImplSumOfMultiplies(pqs, Abs);
end;

class function TECAlgorithms.ImportPoint(const c: IECCurve; const p: IECPoint)
  : IECPoint;
var
  cp: IECCurve;
begin
  cp := p.Curve;
  if (not c.Equals(cp)) then
  begin
    raise EArgumentCryptoLibException.CreateRes(@SInvalidPointLocation);
  end;

  result := c.ImportPoint(p);
end;

class function TECAlgorithms.IsF2mField(const field: IFiniteField): Boolean;
begin
  result := (field.Dimension > 1) and
    (field.Characteristic.Equals(TBigInteger.Two)) and
    (Supports(field, IPolynomialExtensionField));
end;

class function TECAlgorithms.IsF2mCurve(const c: IECCurve): Boolean;
begin
  result := IsF2mField(c.field);
end;

class function TECAlgorithms.IsFpField(const field: IFiniteField): Boolean;
begin
  result := field.Dimension = 1;
end;

class function TECAlgorithms.IsFpCurve(const c: IECCurve): Boolean;
begin
  result := IsFpField(c.field);
end;

class procedure TECAlgorithms.MontgomeryTrick
  (const zs: TCryptoLibGenericArray<IECFieldElement>; off, len: Int32;
  const scale: IECFieldElement);
var
  c: TCryptoLibGenericArray<IECFieldElement>;
  i, j: Int32;
  u, tmp: IECFieldElement;
begin
  // /*
  // * Uses the "Montgomery Trick" to invert many field elements, with only a single actual
  // * field inversion. See e.g. the paper:
  // * "Fast Multi-scalar Multiplication Methods on Elliptic Curves with Precomputation Strategy Using Montgomery Trick"
  // * by Katsuyuki Okeya, Kouichi Sakurai.
  // */

  System.SetLength(c, len);

  c[0] := zs[off];

  i := 0;
  System.Inc(i);
  while (i < len) do
  begin
    c[i] := c[i - 1].Multiply(zs[off + i]);
    System.Inc(i);
  end;
  System.Dec(i);

  if (scale <> Nil) then
  begin
    c[i] := c[i].Multiply(scale);
  end;

  u := c[i].Invert();

  while (i > 0) do
  begin
    j := off + i;
    System.Dec(i);
    tmp := zs[j];
    zs[j] := c[i].Multiply(u);
    u := u.Multiply(tmp);
  end;

  zs[off] := u;
end;

class procedure TECAlgorithms.MontgomeryTrick
  (const zs: TCryptoLibGenericArray<IECFieldElement>; off, len: Int32);
begin
  MontgomeryTrick(zs, off, len, Nil);
end;

class function TECAlgorithms.ReferenceMultiply(const p: IECPoint;
  const k: TBigInteger): IECPoint;
var
  x: TBigInteger;
  q, LP: IECPoint;
  t, i: Int32;
begin
  LP := p;
  x := k.Abs();
  q := LP.Curve.Infinity;
  t := x.BitLength;
  if (t > 0) then
  begin
    if (x.TestBit(0)) then
    begin
      q := LP;
    end;
    i := 1;
    while (i < t) do
    begin
      LP := LP.Twice();
      if (x.TestBit(i)) then
      begin
        q := q.Add(LP);
      end;
      System.Inc(i);
    end;

  end;

  if k.SignValue < 0 then
  begin
    result := q.Negate();
  end
  else
  begin
    result := q;
  end;

end;

class function TECAlgorithms.ShamirsTrick(const p: IECPoint;
  const k: TBigInteger; const q: IECPoint; const l: TBigInteger): IECPoint;
var
  cp: IECCurve;
  LQ: IECPoint;
begin
  cp := p.Curve;
  LQ := q;
  LQ := ImportPoint(cp, LQ);

  result := ImplCheckResult(ImplShamirsTrickJsf(p, k, LQ, l));
end;

class function TECAlgorithms.SumOfMultiplies
  (const ps: TCryptoLibGenericArray<IECPoint>;
  const ks: TCryptoLibGenericArray<TBigInteger>): IECPoint;
var
  count: Int32;
  p: IECPoint;
  c: IECCurve;
  i: Int32;
  imported: TCryptoLibGenericArray<IECPoint>;
  glvEndomorphism: IGlvEndomorphism;
begin
  if ((ps = Nil) or (ks = Nil) or (System.length(ps) <> System.length(ks)) or
    (System.length(ps) < 1)) then
  begin
    raise EArgumentCryptoLibException.CreateRes(@SInvalidArray);
  end;

  count := System.length(ps);

  case count of
    1:
      begin
        result := ps[0].Multiply(ks[0]);
        Exit;
      end;

    2:
      begin
        result := SumOfTwoMultiplies(ps[0], ks[0], ps[1], ks[1]);
        Exit;
      end;

  end;

  p := ps[0];
  c := p.Curve;
  System.SetLength(imported, count);
  imported[0] := p;

  for i := 1 to System.Pred(count) do
  begin
    imported[i] := ImportPoint(c, ps[i]);
  end;

  if Supports(c.GetEndomorphism(), IGlvEndomorphism, glvEndomorphism) then
  begin
    result := ImplCheckResult(ImplSumOfMultipliesGlv(imported, ks,
      glvEndomorphism));
    Exit;
  end;

  result := ImplCheckResult(ImplSumOfMultiplies(imported, ks));
end;

class function TECAlgorithms.SumOfTwoMultiplies(const p: IECPoint;
  const a: TBigInteger; const q: IECPoint; const b: TBigInteger): IECPoint;
var
  cp: IECCurve;
  f2mCurve: IAbstractF2mCurve;
  glvEndomorphism: IGlvEndomorphism;
  LQ: IECPoint;
begin
  cp := p.Curve;
  LQ := q;
  LQ := ImportPoint(cp, LQ);

  // Point multiplication for Koblitz curves (using WTNAF) beats Shamir's trick

  if (Supports(cp, IAbstractF2mCurve, f2mCurve) and (f2mCurve.IsKoblitz)) then
  begin
    result := ImplCheckResult(p.Multiply(a).Add(LQ.Multiply(b)));
    Exit;
  end;

  if Supports(cp.GetEndomorphism(), IGlvEndomorphism, glvEndomorphism) then
  begin
    result := ImplCheckResult
      (ImplSumOfMultipliesGlv(TCryptoLibGenericArray<IECPoint>.Create(p, LQ),
      TCryptoLibGenericArray<TBigInteger>.Create(a, b), glvEndomorphism));
    Exit;
  end;

  result := ImplCheckResult(ImplShamirsTrickWNaf(p, a, LQ, b));
end;

{ TWNafUtilities }

class function TWNafUtilities.ResizeTable
  (const a: TCryptoLibGenericArray<IECPoint>; length: Int32)
  : TCryptoLibGenericArray<IECPoint>;
begin
  result := System.Copy(a);
  System.SetLength(result, length);
end;

class function TWNafUtilities.Trim(const a: TCryptoLibInt32Array; length: Int32)
  : TCryptoLibInt32Array;
begin
  result := System.Copy(a, 0, length);
end;

class function TWNafUtilities.Trim(const a: TCryptoLibByteArray; length: Int32)
  : TCryptoLibByteArray;
begin
  result := System.Copy(a, 0, length);
end;

class procedure TWNafUtilities.Boot;
begin
  FEMPTY_BYTES := Nil;
  FEMPTY_INTS := Nil;
end;

class constructor TWNafUtilities.CreateWNafUtilities;
begin
  TWNafUtilities.Boot;
end;

class function TWNafUtilities.GetWindowSize(bits: Int32;
  const windowSizeCutoffs: array of Int32; maxWidth: Int32): Int32;
var
  w: Int32;
begin
  w := 0;
  while (w < System.length(windowSizeCutoffs)) do
  begin
    if (bits < windowSizeCutoffs[w]) then
    begin
      break;
    end;
    System.Inc(w);
  end;

  result := Max(2, Min(maxWidth, w + 2));
end;

class function TWNafUtilities.GetWindowSize(bits: Int32;
  const windowSizeCutoffs: array of Int32): Int32;
begin
  result := GetWindowSize(bits, windowSizeCutoffs, MAX_WIDTH);
end;

class function TWNafUtilities.GetWindowSize(bits, maxWidth: Int32): Int32;
begin
  result := GetWindowSize(bits, DEFAULT_WINDOW_SIZE_CUTOFFS, maxWidth);
end;

class function TWNafUtilities.GetWindowSize(bits: Int32): Int32;
begin
  result := GetWindowSize(bits, DEFAULT_WINDOW_SIZE_CUTOFFS, MAX_WIDTH);
end;

class procedure TWNafUtilities.ConfigureBasepoint(const p: IECPoint);
var
  c: IECCurve;
  n: TBigInteger;
  bits, ConfWidth: Int32;
begin
  c := p.Curve;
  if (c = Nil) then
  begin
    Exit;
  end;

  n := c.Order;
  if (not n.IsInitialized) then
  begin
    bits := c.FieldSize + 1;
  end
  else
  begin
    bits := n.BitLength;
  end;

  ConfWidth := Min(MAX_WIDTH, GetWindowSize(bits) + 3);

  c.Precompute(p, PRECOMP_NAME, TBasePointCallback.Create(ConfWidth)
    as IBasePointCallback);
end;

class function TWNafUtilities.GenerateCompactNaf(const k: TBigInteger)
  : TCryptoLibInt32Array;
var
  _3k, diff: TBigInteger;
  bits, highBit, &length, zeroes, i, digit: Int32;
  naf: TCryptoLibInt32Array;
begin
  if ((TBits.Asr32(k.BitLength, 16)) <> 0) then
  begin
    raise EArgumentCryptoLibException.CreateRes(@SInvalidBitLength);
  end;
  if (k.SignValue = 0) then
  begin
    result := FEMPTY_INTS;
    Exit;
  end;

  _3k := k.ShiftLeft(1).Add(k);

  bits := _3k.BitLength;
  System.SetLength(naf, TBits.Asr32(bits, 1));

  diff := _3k.&Xor(k);

  highBit := bits - 1;
  &length := 0;
  zeroes := 0;

  i := 1;

  while (i < highBit) do
  begin
    if (not diff.TestBit(i)) then
    begin
      System.Inc(zeroes);
      System.Inc(i);
      continue;
    end;

    if k.TestBit(i) then
    begin
      digit := -1;
    end
    else
    begin
      digit := 1;
    end;

    naf[length] := (digit shl 16) or zeroes;
    System.Inc(length);
    zeroes := 1;

    System.Inc(i, 2);

  end;

  naf[length] := (1 shl 16) or zeroes;
  System.Inc(length);

  if (System.length(naf) > length) then
  begin
    naf := Trim(naf, length);
  end;

  result := naf;
end;

class function TWNafUtilities.GenerateCompactWindowNaf(width: Int32;
  const k: TBigInteger): TCryptoLibInt32Array;
var
  wnaf: TCryptoLibInt32Array;
  pow2, mask, sign, &length, &pos, digit, zeroes: Int32;
  carry: Boolean;
  LK: TBigInteger;
begin
  LK := k;
  if (width = 2) then
  begin
    result := GenerateCompactNaf(LK);
    Exit;
  end;

  if ((width < 2) or (width > 16)) then
  begin
    raise EArgumentCryptoLibException.CreateRes(@SInvalidRange);
  end;
  if ((TBits.Asr32(LK.BitLength, 16)) <> 0) then
  begin
    raise EArgumentCryptoLibException.CreateRes(@SInvalidBitLength);
  end;
  if (LK.SignValue = 0) then
  begin
    result := FEMPTY_INTS;
    Exit;
  end;

  System.SetLength(wnaf, (LK.BitLength div width) + 1);

  // 2^width and a mask and sign bit set accordingly
  pow2 := 1 shl width;
  mask := pow2 - 1;
  sign := TBits.Asr32(pow2, 1);

  carry := false;
  length := 0;
  pos := 0;

  while (pos <= LK.BitLength) do
  begin
    if (LK.TestBit(pos) = carry) then
    begin
      System.Inc(pos);
      continue;
    end;

    LK := LK.ShiftRight(pos);

    digit := LK.Int32Value and mask;
    if (carry) then
    begin
      System.Inc(digit);
    end;

    carry := (digit and sign) <> 0;
    if (carry) then
    begin
      digit := digit - pow2;
    end;

    if length > 0 then
    begin
      zeroes := pos - 1;
    end
    else
    begin
      zeroes := pos;
    end;

    wnaf[length] := (digit shl 16) or zeroes;
    System.Inc(length);
    pos := width;
  end;

  // Reduce the WNAF array to its actual length
  if (System.length(wnaf) > length) then
  begin
    wnaf := Trim(wnaf, length);
  end;

  result := wnaf;
end;

class function TWNafUtilities.GenerateJsf(const g, h: TBigInteger)
  : TCryptoLibByteArray;
var
  digits, j, d0, d1, Offset, n0, n1, u0, u1: Int32;
  jsf: TCryptoLibByteArray;
  k0, k1: TBigInteger;
begin
  digits := Max(g.BitLength, h.BitLength) + 1;

  System.SetLength(jsf, digits);

  k0 := g;
  k1 := h;
  j := 0;
  d0 := 0;
  d1 := 0;

  Offset := 0;

  while (((d0 or d1) <> 0) or (k0.BitLength > Offset) or
    (k1.BitLength > Offset)) do
  begin
    n0 := (Int32(UInt32(k0.Int32Value) shr Offset) + d0) and 7;
    n1 := (Int32(UInt32(k1.Int32Value) shr Offset) + d1) and 7;

    u0 := n0 and 1;
    if (u0 <> 0) then
    begin
      u0 := u0 - (n0 and 2);
      if (((n0 + u0) = 4) and ((n1 and 3) = 2)) then
      begin
        u0 := -u0;
      end;
    end;

    u1 := n1 and 1;
    if (u1 <> 0) then
    begin
      u1 := u1 - (n1 and 2);
      if (((n1 + u1) = 4) and ((n0 and 3) = 2)) then
      begin
        u1 := -u1;
      end;
    end;

    if ((d0 shl 1) = (1 + u0)) then
    begin
      d0 := d0 xor 1;
    end;
    if ((d1 shl 1) = (1 + u1)) then
    begin
      d1 := d1 xor 1;
    end;

    System.Inc(Offset);
    if (Offset = 30) then
    begin
      Offset := 0;
      k0 := k0.ShiftRight(30);
      k1 := k1.ShiftRight(30);
    end;

    jsf[j] := Byte((u0 shl 4) or (u1 and $F));
    System.Inc(j);
  end;

  // Reduce the JSF array to its actual length
  if (System.length(jsf) > j) then
  begin
    jsf := Trim(jsf, j);
  end;

  result := jsf;
end;

class function TWNafUtilities.GenerateNaf(const k: TBigInteger)
  : TCryptoLibByteArray;
var
  _3k, diff: TBigInteger;
  digits, i: Int32;
  naf: TCryptoLibByteArray;
begin
  if (k.SignValue = 0) then
  begin
    result := FEMPTY_BYTES;
    Exit;
  end;

  _3k := k.ShiftLeft(1).Add(k);

  digits := _3k.BitLength - 1;
  System.SetLength(naf, digits);

  diff := _3k.&Xor(k);

  i := 1;

  while i < digits do
  begin
    if (diff.TestBit(i)) then
    begin
      if k.TestBit(i) then
      begin
        naf[i - 1] := Byte(-1);
      end
      else
      begin
        naf[i - 1] := Byte(1);
      end;

      System.Inc(i);
    end;
    System.Inc(i);
  end;

  naf[digits - 1] := 1;

  result := naf;
end;

class function TWNafUtilities.GenerateWindowNaf(width: Int32;
  const k: TBigInteger): TCryptoLibByteArray;
var
  wnaf: TCryptoLibByteArray;
  pow2, mask, sign, &length, &pos, digit: Int32;
  carry: Boolean;
  LK: TBigInteger;
begin
  LK := k;
  if (width = 2) then
  begin
    result := GenerateNaf(LK);
    Exit;
  end;

  if ((width < 2) or (width > 8)) then
  begin
    raise EArgumentCryptoLibException.CreateRes(@SInvalidRange2);
  end;
  if (LK.SignValue = 0) then
  begin
    result := FEMPTY_BYTES;
    Exit;
  end;

  System.SetLength(wnaf, LK.BitLength + 1);

  // 2^width and a mask and sign bit set accordingly
  pow2 := 1 shl width;
  mask := pow2 - 1;
  sign := TBits.Asr32(pow2, 1);

  carry := false;
  length := 0;
  pos := 0;

  while (pos <= LK.BitLength) do
  begin
    if (LK.TestBit(pos) = carry) then
    begin
      System.Inc(pos);
      continue;
    end;

    LK := LK.ShiftRight(pos);

    digit := LK.Int32Value and mask;
    if (carry) then
    begin
      System.Inc(digit);
    end;

    carry := (digit and sign) <> 0;
    if (carry) then
    begin
      digit := digit - pow2;
    end;

    if length > 0 then
    begin
      length := length + (pos - 1);
    end
    else
    begin
      length := length + (pos);
    end;

    wnaf[length] := Byte(digit);
    System.Inc(length);
    pos := width;
  end;

  // Reduce the WNAF array to its actual length
  if (System.length(wnaf) > length) then
  begin
    wnaf := Trim(wnaf, length);
  end;

  result := wnaf;
end;

class function TWNafUtilities.GetNafWeight(const k: TBigInteger): Int32;
var
  _3k, diff: TBigInteger;
begin
  if (k.SignValue = 0) then
  begin
    result := 0;
    Exit;
  end;

  _3k := k.ShiftLeft(1).Add(k);
  diff := _3k.&Xor(k);

  result := diff.BitCount;
end;

class function TWNafUtilities.GetWNafPreCompInfo(const preCompInfo
  : IPreCompInfo): IWNafPreCompInfo;
begin
  result := preCompInfo as IWNafPreCompInfo;
end;

class function TWNafUtilities.GetWNafPreCompInfo(const p: IECPoint)
  : IWNafPreCompInfo;
var
  preCompInfo: IPreCompInfo;
begin
  preCompInfo := p.Curve.GetPreCompInfo(p, PRECOMP_NAME);
  result := GetWNafPreCompInfo(preCompInfo);
end;

class function TWNafUtilities.Precompute(const p: IECPoint; minWidth: Int32;
  includeNegated: Boolean): IWNafPreCompInfo;
begin
  result := p.Curve.Precompute(p, PRECOMP_NAME,
    TWNafCallback.Create(p, minWidth, includeNegated) as IWNafCallback)
    as IWNafPreCompInfo;
end;

class function TWNafUtilities.PrecomputeWithPointMap(const p: IECPoint;
  const pointMap: IECPointMap; const fromWNaf: IWNafPreCompInfo;
  includeNegated: Boolean): IWNafPreCompInfo;
var
  c: IECCurve;
begin
  c := p.Curve;
  result := c.Precompute(p, PRECOMP_NAME, TPointMapCallback.Create(p, pointMap,
    fromWNaf, includeNegated) as IPointMapCallback) as IWNafPreCompInfo;
end;

{ TWNafUtilities.TMapPointCallback }

constructor TWNafUtilities.TMapPointCallback.Create(const wnafPreCompP
  : IWNafPreCompInfo; includeNegated: Boolean; const pointMap: IECPointMap);
begin
  Inherited Create();
  Fm_wnafPreCompP := wnafPreCompP;
  Fm_includeNegated := includeNegated;
  Fm_pointMap := pointMap;
end;

function TWNafUtilities.TMapPointCallback.Precompute(const existing
  : IPreCompInfo): IPreCompInfo;
var
  tempResult: IWNafPreCompInfo;
  twiceP, twiceQ: IECPoint;
  preCompP, preCompQ, preCompNegQ: TCryptoLibGenericArray<IECPoint>;
  i: Int32;
begin
  tempResult := TWNafPreCompInfo.Create();

  tempResult.ConfWidth := Fm_wnafPreCompP.ConfWidth;

  twiceP := Fm_wnafPreCompP.Twice;
  if (twiceP <> Nil) then
  begin
    twiceQ := Fm_pointMap.Map(twiceP);
    tempResult.Twice := twiceQ;
  end;

  preCompP := Fm_wnafPreCompP.PreComp;

  System.SetLength(preCompQ, System.length(preCompP));
  for i := 0 to System.Pred(System.length(preCompP)) do
  begin
    preCompQ[i] := Fm_pointMap.Map(preCompP[i]);
  end;

  tempResult.PreComp := preCompQ;
  tempResult.width := Fm_wnafPreCompP.width;

  if (Fm_includeNegated) then
  begin

    System.SetLength(preCompNegQ, System.length(preCompQ));

    for i := 0 to System.Pred(System.length(preCompNegQ)) do
    begin
      preCompNegQ[i] := preCompQ[i].Negate();
    end;

    tempResult.PreCompNeg := preCompNegQ;
  end;

  result := tempResult;
end;

{ TWNafUtilities.TWNafCallback }

class function TWNafUtilities.TWNafCallback.CheckTable
  (const table: TCryptoLibGenericArray<IECPoint>; reqLen: Int32): Boolean;
begin
  result := (table <> Nil) and (System.length(table) >= reqLen);
end;

class function TWNafUtilities.TWNafCallback.CheckExisting(const existingWNaf
  : IWNafPreCompInfo; width, reqPreCompLen: Int32;
  includeNegated: Boolean): Boolean;
begin
  result := (existingWNaf <> Nil) and
    (existingWNaf.width >= Max(existingWNaf.ConfWidth, width))

    and CheckTable(existingWNaf.PreComp, reqPreCompLen) and
    ((not includeNegated) or CheckTable(existingWNaf.PreCompNeg,
    reqPreCompLen));
end;

constructor TWNafUtilities.TWNafCallback.Create(const p: IECPoint;
  minWidth: Int32; includeNegated: Boolean);
begin
  Inherited Create();
  Fm_p := p;
  FminWidth := minWidth;
  Fm_includeNegated := includeNegated;
end;

function TWNafUtilities.TWNafCallback.Precompute(const existing: IPreCompInfo)
  : IPreCompInfo;
var
  twiceP, isoTwiceP, last: IECPoint;
  c: IECCurve;
  PreComp, PreCompNeg, EMPTY_POINTS: TCryptoLibGenericArray<IECPoint>;
  tempRes, existingWNaf: IWNafPreCompInfo;
  reqPreCompLen, iniPreCompLen, curPreCompLen, pos, width, PromotionCountdown,
    ConfWidth: Int32;
  iso, iso2, iso3: IECFieldElement;
begin
  c := Fm_p.Curve;
  EMPTY_POINTS := Nil;
  existingWNaf := existing as IWNafPreCompInfo;

  width := Max(2, Min(MAX_WIDTH, FminWidth));
  reqPreCompLen := 1 shl (width - 2);

  if (CheckExisting(existingWNaf, width, reqPreCompLen, Fm_includeNegated)) then
  begin
    existingWNaf.DecrementPromotionCountdown;
    result := existingWNaf;
    Exit;
  end;

  tempRes := TWNafPreCompInfo.Create();

  if (existingWNaf <> Nil) then
  begin

    PromotionCountdown := existingWNaf.DecrementPromotionCountdown;
    tempRes.PromotionCountdown := PromotionCountdown;

    ConfWidth := existingWNaf.ConfWidth;
    tempRes.ConfWidth := ConfWidth;

    PreComp := existingWNaf.PreComp;
    PreCompNeg := existingWNaf.PreCompNeg;
    twiceP := existingWNaf.Twice;
  end;

  width := Min(MAX_WIDTH, Max(tempRes.ConfWidth, width));
  reqPreCompLen := 1 shl (width - 2);

  iniPreCompLen := 0;
  if (PreComp = Nil) then
  begin
    PreComp := EMPTY_POINTS;
  end
  else
  begin
    iniPreCompLen := System.length(PreComp);
  end;

  if (iniPreCompLen < reqPreCompLen) then
  begin
    PreComp := TWNafUtilities.ResizeTable(PreComp, reqPreCompLen);

    if (reqPreCompLen = 1) then
    begin
      PreComp[0] := Fm_p.Normalize();
    end
    else
    begin
      curPreCompLen := iniPreCompLen;
      if (curPreCompLen = 0) then
      begin
        PreComp[0] := Fm_p;
        curPreCompLen := 1;
      end;

      if (reqPreCompLen = 2) then
      begin
        PreComp[1] := Fm_p.threeTimes();
      end
      else
      begin
        isoTwiceP := twiceP;
        last := PreComp[curPreCompLen - 1];
        if (isoTwiceP = Nil) then
        begin
          isoTwiceP := PreComp[0].Twice();
          twiceP := isoTwiceP;
          //
          // /*
          // * For Fp curves with Jacobian projective coordinates, use a (quasi-)isomorphism
          // * where 'twiceP' is "affine", so that the subsequent additions are cheaper. This
          // * also requires scaling the initial point's X, Y coordinates, and reversing the
          // * isomorphism as part of the subsequent normalization.
          // *
          // *  NOTE: The correctness of this optimization depends on:
          // *      1) additions do not use the curve's A, B coefficients.
          // *      2) no special cases (i.e. Q +/- Q) when calculating 1P, 3P, 5P, ...
          // */
          if ((not(twiceP.IsInfinity)) and (TECAlgorithms.IsFpCurve(c)) and
            (c.FieldSize >= 64)) then
          begin
            case (c.CoordinateSystem) of
              TECCurveConstants.COORD_JACOBIAN,
                TECCurveConstants.COORD_JACOBIAN_CHUDNOVSKY,
                TECCurveConstants.COORD_JACOBIAN_MODIFIED:

                begin
                  iso := twiceP.GetZCoord(0);
                  isoTwiceP := c.CreatePoint(twiceP.XCoord.ToBigInteger,
                    twiceP.YCoord.ToBigInteger());

                  iso2 := iso.square();
                  iso3 := iso2.Multiply(iso);
                  last := last.scaleX(iso2).scaleY(iso3);

                  if (iniPreCompLen = 0) then
                  begin
                    PreComp[0] := last;
                  end;
                end;

            end;

          end;
        end;

        while (curPreCompLen < reqPreCompLen) do
        begin
          // /*
          // * Compute the new ECPoints for the precomputation array. The values 1, 3,
          // * 5, ..., 2^(width-1)-1 times p are computed
          // */
          last := last.Add(isoTwiceP);
          PreComp[curPreCompLen] := last;
          System.Inc(curPreCompLen);
        end;
      end;
      //
      // /*
      // * Having oft-used operands in affine form makes operations faster.
      // */
      c.NormalizeAll(PreComp, iniPreCompLen,
        reqPreCompLen - iniPreCompLen, iso);
    end;
  end;

  if (Fm_includeNegated) then
  begin

    if (PreCompNeg = Nil) then
    begin
      pos := 0;
      System.SetLength(PreCompNeg, reqPreCompLen);

    end
    else
    begin
      pos := System.length(PreCompNeg);
      if (pos < reqPreCompLen) then
      begin
        PreCompNeg := TWNafUtilities.ResizeTable(PreCompNeg, reqPreCompLen);
      end;
    end;

    while (pos < reqPreCompLen) do
    begin
      PreCompNeg[pos] := PreComp[pos].Negate();
      System.Inc(pos);
    end;
  end;

  tempRes.PreComp := PreComp;
  tempRes.PreCompNeg := PreCompNeg;
  tempRes.Twice := twiceP;
  tempRes.width := width;

  result := tempRes;
end;

{ TWNafUtilities.TBasePointCallback }

constructor TWNafUtilities.TBasePointCallback.Create(ConfWidth: Int32);
begin
  Inherited Create();
  FConfWidth := ConfWidth;
end;

function TWNafUtilities.TBasePointCallback.Precompute(const existing
  : IPreCompInfo): IPreCompInfo;
var
  existingWNaf, tempResult: IWNafPreCompInfo;
begin

  if Supports(existing, IWNafPreCompInfo) then
  begin
    existingWNaf := existing as IWNafPreCompInfo;
  end
  else
  begin
    existingWNaf := Nil;
  end;

  if ((existingWNaf <> Nil) and (existingWNaf.ConfWidth = FConfWidth)) then
  begin
    existingWNaf.PromotionCountdown := 0;
    result := existingWNaf;
    Exit;
  end;

  tempResult := TWNafPreCompInfo.Create();

  tempResult.PromotionCountdown := 0;
  tempResult.ConfWidth := FConfWidth;

  if (existingWNaf <> Nil) then
  begin
    tempResult.PreComp := existingWNaf.PreComp;
    tempResult.PreCompNeg := existingWNaf.PreCompNeg;
    tempResult.Twice := existingWNaf.Twice;
    tempResult.width := existingWNaf.width;
  end;
  result := tempResult;
end;

{ TWNafUtilities.TPointMapCallback }

class function TWNafUtilities.TPointMapCallback.CheckTable
  (const table: TCryptoLibGenericArray<IECPoint>; reqLen: Int32): Boolean;
begin
  result := ((table <> Nil) and (System.length(table) >= reqLen));
end;

class function TWNafUtilities.TPointMapCallback.CheckExisting(const existingWNaf
  : IWNafPreCompInfo; width, reqPreCompLen: Int32;
  includeNegated: Boolean): Boolean;
begin
  result := ((existingWNaf <> Nil) and (existingWNaf.width >= width) and
    (CheckTable(existingWNaf.PreComp, reqPreCompLen)) and
    ((not includeNegated) or (CheckTable(existingWNaf.PreCompNeg,
    reqPreCompLen))));
end;

constructor TWNafUtilities.TPointMapCallback.Create(const p: IECPoint;
  const pointMap: IECPointMap; const fromWNaf: IWNafPreCompInfo;
  includeNegated: Boolean);
begin
  Inherited Create();
  Fm_p := p;
  FpointMap := pointMap;
  FfromWNaf := fromWNaf;
  FIncludeNegated := includeNegated;
end;

function TWNafUtilities.TPointMapCallback.Precompute(const existing
  : IPreCompInfo): IPreCompInfo;
var
  existingWNaf: IWNafPreCompInfo;
  width, reqPreCompLen, i: Int32;
  tempResult: IWNafPreCompInfo;
  twiceFrom, Ltwice: IECPoint;
  LpreCompFrom, LpreComp, LpreCompNeg: TCryptoLibGenericArray<IECPoint>;
begin
  if Supports(existing, IWNafPreCompInfo) then
  begin
    existingWNaf := existing as IWNafPreCompInfo;
  end
  else
  begin
    existingWNaf := Nil;
  end;
  width := FfromWNaf.width;
  reqPreCompLen := System.length(FfromWNaf.PreComp);

  if (CheckExisting(existingWNaf, width, reqPreCompLen, FIncludeNegated)) then
  begin
    existingWNaf.DecrementPromotionCountdown;
    result := existingWNaf;
    Exit;
  end;

  (*
    * TODO Ideally this method would support incremental calculation, but given the
    * existing use-cases it would be of little-to-no benefit.
  *)
  tempResult := TWNafPreCompInfo.Create();

  tempResult.PromotionCountdown := FfromWNaf.PromotionCountdown;

  twiceFrom := FfromWNaf.Twice;
  if (twiceFrom <> Nil) then
  begin
    Ltwice := FpointMap.Map(twiceFrom);
    tempResult.Twice := Ltwice;
  end;

  LpreCompFrom := FfromWNaf.PreComp;
  System.SetLength(LpreComp, System.length(LpreCompFrom));

  for i := 0 to System.Pred(System.length(LpreCompFrom)) do
  begin
    LpreComp[i] := FpointMap.Map(LpreCompFrom[i]);
  end;
  tempResult.PreComp := LpreComp;
  tempResult.width := width;

  if (FIncludeNegated) then
  begin
    System.SetLength(LpreCompNeg, System.length(LpreComp));

    for i := 0 to System.Pred(System.length(LpreCompNeg)) do
    begin
      LpreCompNeg[i] := LpreComp[i].Negate();
    end;
    tempResult.PreCompNeg := LpreCompNeg;
  end;

  result := tempResult;
end;

{ TEndoUtilities }

class function TEndoUtilities.CalculateB(const k, g: TBigInteger; t: Int32)
  : TBigInteger;
var
  negative, extra: Boolean;
  b: TBigInteger;
begin
  negative := (g.SignValue < 0);
  b := k.Multiply(g.Abs());
  extra := b.TestBit(t - 1);
  b := b.ShiftRight(t);
  if (extra) then
  begin
    b := b.Add(TBigInteger.One);
  end;

  if negative then
  begin
    result := b.Negate();
  end
  else
  begin
    result := b;
  end;
end;

class function TEndoUtilities.DecomposeScalar(const p: IScalarSplitParameters;
  const k: TBigInteger): TCryptoLibGenericArray<TBigInteger>;
var
  bits: Int32;
  b1, b2, a, b: TBigInteger;
begin

  bits := p.bits;
  b1 := CalculateB(k, p.G1, bits);
  b2 := CalculateB(k, p.G2, bits);

  a := k.Subtract((b1.Multiply(p.V1A)).Add(b2.Multiply(p.V2A)));
  b := (b1.Multiply(p.V1B)).Add(b2.Multiply(p.V2B)).Negate();

  result := TCryptoLibGenericArray<TBigInteger>.Create(a, b);
end;

class function TEndoUtilities.MapPoint(const endomorphism: IECEndomorphism;
  const p: IECPoint): IECPoint;
var
  c: IECCurve;
  PreComp: IEndoPreCompInfo;
begin
  c := p.Curve;
  PreComp := c.Precompute(p, PRECOMP_NAME, TEndoCallback.Create(endomorphism, p)
    as IEndoCallback) as IEndoPreCompInfo;

  result := PreComp.MappedPoint;
end;

{ TEndoUtilities.TEndoCallback }

class function TEndoUtilities.TEndoCallback.CheckExisting(const existingEndo
  : IEndoPreCompInfo; const endomorphism: IECEndomorphism): Boolean;
begin
  result := ((existingEndo <> Nil) and
    (existingEndo.endomorphism = endomorphism) and
    (existingEndo.MappedPoint <> Nil));
end;

constructor TEndoUtilities.TEndoCallback.Create(const endomorphism
  : IECEndomorphism; const p: IECPoint);
begin
  Inherited Create();
  Fendomorphism := endomorphism;
  Fp := p;
end;

function TEndoUtilities.TEndoCallback.Precompute(const existing: IPreCompInfo)
  : IPreCompInfo;
var
  existingEndo: IEndoPreCompInfo;
  MappedPoint: IECPoint;
  tempResult: IEndoPreCompInfo;
begin

  if Supports(existing, IEndoPreCompInfo) then
  begin
    existingEndo := existing as IEndoPreCompInfo;
  end
  else
  begin
    existingEndo := Nil;
  end;

  if (CheckExisting(existingEndo, Fendomorphism)) then
  begin
    result := existingEndo;
    Exit;
  end;

  MappedPoint := Fendomorphism.pointMap.Map(Fp);

  tempResult := TEndoPreCompInfo.Create() as IEndoPreCompInfo;
  tempResult.endomorphism := Fendomorphism;
  tempResult.MappedPoint := MappedPoint;
  result := tempResult as IPreCompInfo;
end;

{ TFixedPointUtilities }

class function TFixedPointUtilities.TFixedPointCallback.CheckTable
  (const table: IECLookupTable; n: Int32): Boolean;
begin
  result := (table <> Nil) and (table.Size >= n);
end;

class function TFixedPointUtilities.TFixedPointCallback.CheckExisting
  (const existingFP: IFixedPointPreCompInfo; n: Int32): Boolean;
begin
  result := (existingFP <> Nil) and CheckTable(existingFP.LookupTable, n);
end;

class function TFixedPointUtilities.GetCombSize(const c: IECCurve): Int32;
var
  Order: TBigInteger;
begin
  Order := c.Order;
  if (not(Order.IsInitialized)) then
  begin
    result := c.FieldSize + 1;
  end
  else
  begin
    result := Order.BitLength;
  end;
end;

class function TFixedPointUtilities.GetFixedPointPreCompInfo(const preCompInfo
  : IPreCompInfo): IFixedPointPreCompInfo;
begin
  result := preCompInfo as IFixedPointPreCompInfo;
end;

class function TFixedPointUtilities.Precompute(const p: IECPoint)
  : IFixedPointPreCompInfo;
var
  c: IECCurve;
begin
  c := p.Curve;

  result := c.Precompute(p, PRECOMP_NAME, TFixedPointCallback.Create(p)
    as IFixedPointCallback) as IFixedPointPreCompInfo;
end;

{ TFixedPointUtilities.TFixedPointCallback }

constructor TFixedPointUtilities.TFixedPointCallback.Create(const p: IECPoint);
begin
  Inherited Create();
  Fm_p := p;
end;

function TFixedPointUtilities.TFixedPointCallback.Precompute(const existing
  : IPreCompInfo): IPreCompInfo;
var
  bit, bits, minWidth, n, d, i, step: Int32;
  existingFP: IFixedPointPreCompInfo;
  pow2Table, LookupTable: TCryptoLibGenericArray<IECPoint>;
  pow2: IECPoint;
  c: IECCurve;
  tempResult: IFixedPointPreCompInfo;
begin
  if Supports(existing, IFixedPointPreCompInfo) then
  begin
    existingFP := existing as IFixedPointPreCompInfo;
  end
  else
  begin
    existingFP := Nil;
  end;

  c := Fm_p.Curve;
  bits := TFixedPointUtilities.GetCombSize(c);
  if bits > 250 then
  begin
    minWidth := 6
  end
  else
  begin
    minWidth := 5
  end;
  n := 1 shl minWidth;

  if (CheckExisting(existingFP, n)) then
  begin
    result := existingFP;
    Exit;
  end;

  d := (bits + minWidth - 1) div minWidth;

  System.SetLength(pow2Table, minWidth + 1);

  pow2Table[0] := Fm_p;
  for i := 1 to System.Pred(minWidth) do
  begin
    pow2Table[i] := pow2Table[i - 1].TimesPow2(d);
  end;

  // This will be the 'offset' value
  pow2Table[minWidth] := pow2Table[0].Subtract(pow2Table[1]);

  c.NormalizeAll(pow2Table);

  System.SetLength(LookupTable, n);
  LookupTable[0] := pow2Table[0];

  bit := minWidth - 1;
  while bit >= 0 do
  begin
    pow2 := pow2Table[bit];

    step := 1 shl bit;

    i := step;

    while i < n do
    begin
      LookupTable[i] := LookupTable[i - step].Add(pow2);

      System.Inc(i, step shl 1);
    end;

    System.Dec(bit);
  end;

  c.NormalizeAll(LookupTable);

  tempResult := TFixedPointPreCompInfo.Create();
  tempResult.LookupTable := c.CreateCacheSafeLookupTable(LookupTable, 0,
    System.length(LookupTable));
  tempResult.Offset := pow2Table[minWidth];
  tempResult.width := minWidth;
  result := tempResult;
end;

end.
