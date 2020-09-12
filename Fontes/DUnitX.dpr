program DUnitX;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}
uses
  System.Classes,
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  Horse,
  Horse.JWT,
  Horse.Jhonson,
  Horse.Compression,
  Horse.HandleException,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  Services.Login in 'Services\Services.Login.pas',
  Services.Usuario in 'Services\Services.Usuario.pas',
  Controllers.Login in 'Controllers\Controllers.Login.pas',
  Controllers.Usuario in 'Controllers\Controllers.Usuario.pas',
  Controllers.ApiMethods in 'Controllers\Controllers.ApiMethods.pas',
  Tests.Controllers.Usuario in 'Tests\Controllers\Tests.Controllers.Usuario.pas',
  Tests.Controllers.ApiMethods in 'Tests\Controllers\Tests.Controllers.ApiMethods.pas';

var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger: ITestLogger;

begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  exit;
{$ENDIF}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;

    //Create the test runner
    runner := TDUnitX.CreateRunner;

    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;

    //tell the runner how we will log things
    //Log to the console window
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);

    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    runner.FailsOnNoAsserts := False; //When true, Assertions must be made during tests;

    //Run horse
    TThread.CreateAnonymousThread(
      procedure
      begin
        THorse
          .Use(Compression())
          .Use(Jhonson)
          .Use(HandleException)
          .Use('/Api', HorseJWT('rest-api-horse'));

        Controllers.Login.Registry;
        Controllers.ApiMethods.Registry;
        Controllers.Usuario.Registry;

        THorse.Listen(9000);
      end).Start;

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if (TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause) then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
