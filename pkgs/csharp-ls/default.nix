{
  lib,
  buildDotnetGlobalTool,
  dotnetCorePackages,
  versionCheckHook,
  nix-update-script,
}: let
  dotnet-sdk = dotnetCorePackages.sdk_9_0;
in
  buildDotnetGlobalTool rec {
    pname = "csharp-ls";
    version = "0.18.0";

    nugetHash = "sha256-VSlyAt5c03Oiha21ZyQ4Xm/2iIse0h1eVrVpu+nWW3s=";

    inherit dotnet-sdk;
    dotnet-runtime = dotnet-sdk;

    nativeInstallCheckInputs = [
      versionCheckHook
    ];
    versionCheckProgramArg = "--version";
    doInstallCheck = true;

    meta = {
      description = "Roslyn-based LSP language server for C#";
      mainProgram = "csharp-ls";
      homepage = "https://github.com/razzmatazz/csharp-language-server";
      changelog = "https://github.com/razzmatazz/csharp-language-server/releases/tag/v${version}";
      license = lib.licenses.mit;
      platforms = lib.platforms.unix;
      maintainers = with lib.maintainers; [GaetanLepage];
    };
  }

