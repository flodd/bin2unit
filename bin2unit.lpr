program bin2unit;
(*
  bin2unit - bin to pascal converter               
  ----------------------------------
  http://itaprogaming.free.fr
  (c) 2008-2010 - Francesco Lombardi

  --- Description --------------------------------------------------------------
  A small utility to convert binary files to a format suitable for using it with
  Free Pascal.  I made it mainly for converting graphic and  audio files for gba 
  and nds, but it can be used for other platforms too, I suppose =P
  bin2unit works in two modes:
  
    * unit mode = it creates  a single .pp file, that contains  big const arrays
                  where it is stored  the  binary's datas converted  from passed
                  files. 
  
    * asm mode  = it creates .s files, that contain the binary's datas converted
                  from passed files, and a  .pp unit, that  includes the  object 
                  files (.o) (that come from the .s ones, by  assembling it) and 
                  declares the  variables needed  to access the  datas stored in 
                  these  object  files.  ASM mode  is  useful  when you  want to 
                  relocate datas into a specific region of the executable. 

  --- Usage --------------------------------------------------------------------
  Usage: bin2unit [-<options>] [binfile]
  Example: bin2unit -Stext -A2 -Nmyvar image1.bmp image2.pcx 
  Options:
   -U          Creates a pascal unit from the binary file. -S and -A are ignored
   -S<string>  Relocates data in a specified section (default=rodata)
   -A<integer> Sets alignment value (default=4)
   -N<string>  Sets variable base name (default=first binfile)
   -O<string>  Sets output path (default=first binfile)
   -V          Shows version info
   -? or -H    Shows help

  --- History log --------------------------------------------------------------
  ver.0.6  = fixed a bug that afflicted files without path
  ver.0.5  = fixed a warning in the generated asm code
  ver.0.4  = (private release) added output path option
  ver.0.3  = (private release) added multiple files handling
  ver.0.2  = (private release) corrected a bug in path handling
  ver.0.1  = (private release) added some command line switches
*)

{$mode objfpc}

uses
  Classes, SysUtils;

const
  VERSION = '0.6';
  BUILD_DATE = 'Wed, 21 April 2010 19.23.54 GMT';
  COPYRIGHT = '(c) 2008-2014  Francesco Lombardi';
  cCRLF = #13#10;

function IsInteger(S: string): boolean;
begin
  try
    result := true;
    StrToInt(S);
  except on E: EConvertError do
    result := false;
  end;
end;

procedure WriteString(const s: TStream; aStr: ansistring);
begin
  if aStr = '' then 
    exit;
  s.write(pchar(aStr)^, length(aStr));
end;


(* Convert binary files to ASM *)
procedure ConvertFileToASM(var aFileList: TStringList; aResFileName: ansistring; 
  aSection: ansistring; aAlign: integer; aOutPath: ansistring);
var
  j, i, c: integer;
  InputFile: TFileStream;
  Line: ansistring;
  b: Byte;
  OutputStream,
   OutputUnit: TFileStream;
  filename: ansistring;
  filepath: ansistring;
  fileext: ansistring;
begin
  if aFileList = nil then
    exit;

  if aFileList.Count > 0 then
  begin
    if aOutPath = '' then
      filepath := ExtractFilePath(aFileList.strings[0])
    else
      filepath := aOutPath;

    if filepath <> '' then
    if filepath[length(filepath)] <> '/' then
      filepath := filepath + '/';
      
    filepath := SetDirSeparators(filepath);

    if aResFileName = '' then 
    begin
      filename := ExtractFileName(aFileList.Strings[0]);
      filename := ChangeFileExt(filename, '');
    end else
      filename := aResFileName;

    OutputUnit := TFileStream.Create(LowerCase(filepath + filename + '.pp'), fmCreate or fmShareDenyWrite);
    try  
      WriteString(OutputUnit, '(*' + cCRLF);
      WriteString(OutputUnit, #9 + 'Generated by bin2unit ver.' + VERSION + cCRLF);
      WriteString(OutputUnit, #9 + COPYRIGHT + cCRLF);
      WriteString(OutputUnit, '*)' + cCRLF);
      WriteString(OutputUnit, cCRLF);

      WriteString(OutputUnit, 'unit ' + filename + ';' + cCRLF + cCRLF);
      WriteString(OutputUnit, '{$mode objfpc}' + cCRLF + cCRLF);
      WriteString(OutputUnit, 'interface' + cCRLF + cCRLF);

      WriteString(OutputUnit, 'var' + cCRLF );

      for j := 0 to aFileList.Count - 1 do
      begin
        c := 0;
        b := 0;

        if aOutPath = '' then
          filepath := ExtractFilePath(aFileList.strings[j])
        else
          filepath := aOutPath;

        if filepath <> '' then
        if filepath[length(filepath)] <> '/' then
          filepath := filepath + '/';
          
        filepath := SetDirSeparators(filepath);        
        
        
        fileext := ExtractFileExt(aFileList.strings[j]);
        if fileext[1] = '.' then
          Delete(fileext, 1, 1);

        filename := ExtractFileName(aFileList.Strings[j]);
        filename := ChangeFileExt(filename, '');
      
        WriteString(OutputUnit, '{$l ' + filename + '.o}' + cCRLF);
        WriteString(OutputUnit, #9 + filename + '_' + fileext + ': array [0..0] of byte; cvar; external;' + cCRLF);
        WriteString(OutputUnit, #9 + filename + '_' + fileext + '_end: array [0..0] of byte; cvar; external;' + cCRLF);
        WriteString(OutputUnit, #9 + filename + '_' + fileext + '_size: longword; cvar; external;' + cCRLF + cCRLF);        

        OutputStream := TFileStream.Create(LowerCase(filepath + filename + '.s'), fmCreate or fmShareDenyWrite);
        try  
          WriteString(OutputStream, '# Generated by bin2unit ver.' + VERSION + cCRLF);
          WriteString(OutputStream, '# ' + COPYRIGHT + cCRLF);
          WriteString(OutputStream, cCRLF);

          WriteString(OutputStream, #9'.section .' + aSection + cCRLF);
          WriteString(OutputStream, #9'.balign ' + IntToStr(aAlign) + cCRLF);
          InputFile := TFileStream.Create(aFileList.strings[j], fmOpenRead Or fmShareDenyWrite);
          try
            WriteString(OutputStream, #9'.global ' + filename + '_' + fileext + '_size' + cCRLF);
            WriteString(OutputStream, filename + '_' + fileext + '_size' + ': .int ' + IntToStr(InputFile.Size) + cCRLF);
            WriteString(OutputStream, #9'.global ' + filename + '_' + fileext + cCRLF);
            WriteString(OutputStream, filename + '_' + fileext + ':' + cCRLF);

            Line := #9'.byte ';
            for i := 1 to InputFile.Size do
            begin
              Inc(c);
              InputFile.Read(b, SizeOf(b));
              Line := Line +  Format('%3u', [b]);
              if (i < InputFile.size) and (c < 16) then
                Line := Line + ',';
              if (c = 16) or (i = InputFile.Size) then
              begin
                Line := Line + cCRLF;
                WriteString(OutputStream, Line);
                Line := #9'.byte ';
                c := 0;
              end;
            end;
            WriteString(OutputStream, #9'.global ' + filename + '_' + fileext + '_end' + cCRLF);
            WriteString(OutputStream, filename + '_' + fileext + '_end' + ':' + cCRLF);
          finally
            InputFile.Free;
          end;
        finally
          OutputStream.Free;
        end;
      end;
      WriteString(OutputUnit, 'implementation' + cCRLF + cCRLF);
      WriteString(OutputUnit, cCRLF);
      WriteString(OutputUnit,'end.' + cCRLF);
    finally
      OutputUnit.Free;
    end;
  end;
end;

(* Convert binary files to units *)
procedure ConvertFileToUnit(var aFileList: TStringList; aResFileName: ansistring; 
  aOutPath: ansistring);
var
  j, i, c: integer;
  InputFile: TFileStream;
  Line: ansistring;
  b: Byte;
  OutputStream: TFileStream;
  filename: ansistring;
  filepath: ansistring;
  fileext: ansistring;
begin
  if aFileList = nil then
    exit;

  if aFileList.Count > 0 then
  begin
    if aOutPath = '' then
      filepath := ExtractFilePath(aFileList.strings[0])
    else
      filepath := aOutPath;

    if filepath <> '' then
    if filepath[length(filepath)] <> '/' then
      filepath := filepath + '/';

    filepath := SetDirSeparators(filepath);

    if aResFileName = '' then 
    begin
      filename := ExtractFileName(aFileList.Strings[0]);
      filename := ChangeFileExt(filename, '');
    end else
      filename := aResFileName;

    OutputStream := TFileStream.Create(LowerCase(filepath + filename + '.pp'), fmCreate or fmShareDenyWrite);
    try  
      WriteString(OutputStream, '(*' + cCRLF);
      WriteString(OutputStream, #9 + 'Generated by bin2unit ver.' + VERSION + cCRLF);
      WriteString(OutputStream, #9 + COPYRIGHT + cCRLF);
      WriteString(OutputStream, '*)' + cCRLF);
      WriteString(OutputStream, cCRLF);

      WriteString(OutputStream, 'unit ' + filename + ';' + cCRLF + cCRLF);
      WriteString(OutputStream, '{$mode objfpc}' + cCRLF + cCRLF);
      WriteString(OutputStream, 'interface' + cCRLF + cCRLF);
      WriteString(OutputStream, 'const' + cCRLF );

      for j := 0 to aFileList.Count - 1 do
      begin
        c := 0;
        b := 0;
        filepath := ExtractFilePath(aFileList.strings[j]);
        fileext := ExtractFileExt(aFileList.strings[j]);
        if fileext[1] = '.' then
          Delete(fileext, 1, 1);

        filename := ExtractFileName(aFileList.Strings[j]);
        filename := ChangeFileExt(filename, '');

        InputFile := TFileStream.Create(aFileList.strings[j], fmOpenRead Or fmShareDenyWrite);
        try
          WriteString(OutputStream, #9 + filename + '_' + fileext + '_size = ' + IntToStr(InputFile.Size) + ';' + cCRLF);
          WriteString(OutputStream, #9 + filename + '_' + fileext + ': array [0..' + IntToStr(InputFile.Size) + ' - 1] of byte ='  + cCRLF);
          WriteString(OutputStream, #9#9 + '(' + cCRLF);
          Line := #9#9#9;
          for i := 1 to InputFile.Size do
          begin
            Inc(c);
            InputFile.Read(b, SizeOf(b));
            Line := Line + '$' + IntToHex(b,2);
            if i < InputFile.size then
              Line := Line + ',';
            if (c = 16) or (i = InputFile.Size) then
            begin
              Line := Line + cCRLF;
              WriteString(OutputStream, Line);
              Line := #9#9#9;
              c := 0;
            end;
          end;
          WriteString(OutputStream, #9#9 + ');' + cCRLF + cCRLF);
        finally
          InputFile.Free;
        end;
      end;
      WriteString(OutputStream, 'implementation' + cCRLF + cCRLF);
      WriteString(OutputStream, cCRLF);
      WriteString(OutputStream,'end.' + cCRLF);
    finally
      OutputStream.Free;
    end;
  end;
end;

procedure GetParams();
var
  OutASM: boolean = true;
  ch: char;
  params: ansistring;
  i: integer;
  sect: ansistring = 'rodata';
  algn: integer = 4;
  varname: ansistring;
  outputpath: ansistring;
  filelist: TStringList;

    procedure VersionScreen;
    begin
      Writeln('bin2unit ver.', VERSION, ' - ' + COPYRIGHT);
      writeln();
      writeln('A small utility to convert binary files to pascal units');
    end;

    procedure HelpScreen;
    begin
      Writeln;
      VersionScreen;
      writeln('Usage: bin2unit [-<options>] [binfile]');
      writeln('Example: bin2unit -Stext -A2 -Nmyvar image1.bmp image2.pcx');
      writeln('Options:');
      writeln('  -U          Creates a pascal unit from the binary file. -S and -A are ignored');
      writeln('  -S<string>  Relocates data in a specified section (default=rodata)');
      writeln('  -A<integer> Sets alignment value (default=4)');
      writeln('  -N<string>  Sets variable base name (default={first binfile})');
      writeln('  -O<string>  Sets output path (default={first binfile})');
      writeln('  -V          Shows version info');
      writeln('  -? or -H    Shows help');
      writeln;
      halt(1);
    end;

begin
  if paramcount < 1 then
  begin
    VersionScreen;
    writeln('  -? or -H for help');
    exit;
  end else
  begin
    filelist := TStringList.Create;

    for i := 1 to paramcount do
    begin
      params := paramstr(i);
      if (params[1] = '-') then
      begin
        ch := upcase(params[2]);
        delete(params, 1, 2);
        case ch of
          'U' : OutASM := false;
          'S' : sect := params;
          'A' : begin
            if IsInteger(params) then
              algn := StrToInt(params);
          end;
          'V' : begin
            Writeln('bin2unit ver.', VERSION, ' - ' + COPYRIGHT);
            Writeln('   built on ' + BUILD_DATE);
            Writeln;
            Halt;
          end;
          'N' : varname := params;
          'O' : begin
            if DirectoryExists(params) then 
              outputpath := params;
          end;
          '?','H' : Helpscreen;
        end;
      end else
      begin
        if FileExists(params) then
          filelist.add(params);
      end;
    end;
  end;

  if filelist.count > 0 then
  begin
    if OutASM then
      ConvertFileToASM(filelist, varname, sect, algn, outputpath)
    else
      ConvertFileToUnit(filelist, varname, outputpath);
    if filelist <> nil then
      filelist.free;
  end else
    HelpScreen;
end;


{$R bin2unit.res}

begin
  try
    GetParams;
  except
    on E: Exception do
    begin
      WriteLn(E.Message);
      exit;
    end;
  end;
end.
