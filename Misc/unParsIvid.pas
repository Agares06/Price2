unit unParsIvid;

interface

uses
  System.SysUtils, System.Classes,
  unGlobals;

function CutStr(StartCode, EndCode: string; var Dest: string): string;
procedure StrBtwTags(resp, strt: string; var outs: string);
procedure CleanStr(var Dest: string);
function nextLIN(var dest: string): boolean;
procedure ParsGrpListIv(presp : string; var gp_list: TGroup);
procedure ParsPriceIv(resp: string; var prc: TPrice);

implementation

function CutStr(StartCode, EndCode: string; var Dest: string): string;
  var
    pos1: integer;
  begin
    Result := '';

    pos1 := Pos(StartCode, Dest);
    if pos1 > 0 then
    begin
      Delete(Dest, 1, pos1+Length(StartCode)-1);
      pos1 := Pos(EndCode, Dest);
      if pos1 > 0 then
      begin
        Result := Copy(Dest, 1, pos1-1);
        Delete(Dest, 1, pos1-1);
      end
      else
      begin
        Result := Dest;
        Dest := '';
      end;
    end;
  end;

procedure StrBtwTags(resp, strt: string; var outs: string);
  var
    bc, ec, pos1, pos2: integer;
  begin
    outs := '';

    pos1 := Pos(strt, resp);
    if pos1 > 0 then
    begin
      Delete(resp, 1, pos1-1);
      outs := '';
      bc := 0;
      ec := 0;

      repeat
        pos1 := Pos('<', resp);
        pos2 := Pos('>', resp);
        if pos1 < pos2 then
        begin
          bc := bc+1;
          outs := outs+Copy(resp, 1, pos1);
          Delete(resp, 1, pos1);
        end
        else
        begin
          ec := ec+1;
          outs := outs+Copy(resp, 1, pos2);
          Delete(resp, 1, pos2);
        end;
      until bc = ec;
    end;
  end;

procedure CleanStr(var Dest: string);
  var
    pos1: integer;
  begin
    pos1 := Pos('<' , Dest);

    if pos1 > 0 then
      Delete(Dest, pos1, Length(Dest)-pos1+1);

    Dest := Trim(Dest);
  end;

function nextLIN(var dest: string): boolean;
  var
    p1, p2, p3: integer;
    hs1: string;
  begin
    Result := True;

    p1 := Pos('img', dest);
    p3 := Pos('ref' ,dest, Pos('ref', dest)+1);

    if p3 < p1 then
    begin
      Result := False;

      hs1 := dest;
      Delete(hs1, 1, p3-1);
      p1 := Pos('img', hs1);
      p2 := Pos('ref' ,hs1, Pos('ref', hs1)+1);
      if p2 < p1 then
        Result := True;
    end;

    if not Result then
      Delete(dest, 1, p3-2);
  end;

procedure CleanPriceDupl(var prc: TPrice);
  var
    i1, curp, cnt: integer;
    pr1: TPriceRec;
  begin
    curp := Length(prc)-1;

    while curp > 0 do
    begin
      pr1.name := prc[curp].name;
      pr1.prc := prc[curp].prc;

      cnt := 0;
      for i1 := curp-1 to 0 do
        if (pr1.name = prc[i1].name) and (pr1.prc = prc[i1].prc) then
        begin
          Delete(prc, i1, 1);
          cnt := cnt+1;
        end;
      curp := curp-1-cnt;
    end;
  end;

procedure ParsGrpListIv(presp : string; var gp_list: TGroup);
  var
    pos1, pos2, pos3: integer;
    gl1: TGroupLink;
    trig1, trig_s: boolean;
  begin
    SetLength(gp_list, 0);

    pos3 := Pos('item__m-has-submenu', presp);
    Delete(presp, 1, pos3);

    repeat
      pos3 := Pos('href="/shop/', presp);

      if pos3 > 0 then
      if nextLIN(presp) then
      begin
        Delete(presp, 1, pos3);

        pos1 := Pos('/">', presp);
        pos2 := Pos('" class=', presp);
        trig1 := True;
        if pos1 = 0 then
          trig1 := False
        else
          if (pos2 <> 0) and (pos2 < pos1) then
            trig1 := False;
        if not trig1 then
        begin
          gl1.link := 'https://ru.ivideon.com/'+
            CutStr('ref="/', '" class=', presp);
          gl1.name := CutStr('<span>', '</span>', presp)
        end
        else
        begin
          gl1.link := 'https://ru.ivideon.com/'+
            CutStr('ref="/', '">', presp);
          gl1.name := CutStr('">', '</a>', presp);
        end;
        CleanStr(gl1.name);
        CleanStr(gl1.link);

        if (gl1.name <> '') and (gl1.link <> '') then
          Insert(gl1, gp_list, Length(gp_list));
      end;
    until pos3 <= 0;
  end;

procedure ParsPriceIv(resp: string; var prc: TPrice);
  var
    pos1: integer;
    pr1: TPriceRec;
    st1: string;
  begin
    SetLength(prc, 0);

    repeat
      pos1 := Pos('iv-adaptive-template__product-list-item iv-products-grid__item', resp);
      if pos1 > 0 then
      begin
        Delete(resp, 1, pos1);
        pr1.name := CutStr('product_name" value="', '">', resp);
        pr1.pict_link := 'https://ru.ivideon.com/shop/'+
            CutStr('product_image" value="/shop/', '">', resp);
        try
          st1 := CutStr('product_price_num" value="', '">', resp);
          pr1.prc := StrToFloat(st1);
        except
          pr1.prc := 0;
        end;
        pr1.link := 'https://ru.ivideon.com/shop/'+
            CutStr('<a class="" href="/shop/', '">', resp);
        pr1.descr := CutStr('product-list-product-description">', '</div>', resp);
        CleanStr(pr1.descr);

        Insert(pr1, prc, Length(prc));
      end;
    until pos1 <= 0;

    CleanPriceDupl(prc);
  end;


end.
