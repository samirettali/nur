{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  typescript-go,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  fd,
  ripgrep,
  makeBinaryWrapper,
}:
buildNpmPackage (finalAttrs: {
  pname = "pi-coding-agent";
  version = "0.65.2";

  src = fetchFromGitHub {
    owner = "badlogic";
    repo = "pi-mono";
    tag = "v${finalAttrs.version}";
    hash = "sha256-nHCQboyRT8k2t7dD0knmQSaUciQua17518CG/3jC7Rg=";
  };

  patches = [
    ./normalize-package-display-paths.patch
  ];

  npmDepsHash = "sha256-G4eEL1YGrE+iWnAQvwiXu46rX/nX2iGhsxuckfmHNPA=";
  npmDepsFetcherVersion = 2;
  npmWorkspace = "packages/coding-agent";

  # Skip native module rebuild for unneeded workspaces.
  npmRebuildFlags = ["--ignore-scripts"];

  nativeBuildInputs = [
    typescript-go
    makeBinaryWrapper
  ];

  # Build workspace dependencies in order, then the CLI itself.
  buildPhase = ''
    runHook preBuild

    tsgo -p packages/ai/tsconfig.build.json
    tsgo -p packages/tui/tsconfig.build.json
    tsgo -p packages/agent/tsconfig.build.json
    npm run build --workspace=packages/coding-agent

    runHook postBuild
  '';

  # Replace runtime workspace symlinks with real copies.
  postInstall = ''
    local nm="$out/lib/node_modules/pi-monorepo/node_modules"
    local pkgRoot="$out/lib/node_modules/pi-monorepo"
    local shareRoot="$out/share/pi-coding-agent"

    for ws in @mariozechner/pi-ai:packages/ai \
              @mariozechner/pi-agent-core:packages/agent \
              @mariozechner/pi-tui:packages/tui; do
      IFS=: read -r pkg src <<< "$ws"
      rm "$nm/$pkg"
      cp -r "$src" "$nm/$pkg"
    done

    find "$nm" -type l -lname '*/packages/*' -delete
    find "$nm/.bin" -xtype l -delete

    mkdir -p "$shareRoot"
    cp "$pkgRoot/package.json" "$shareRoot/"
    cp "$pkgRoot/README.md" "$shareRoot/"
    cp "$pkgRoot/CHANGELOG.md" "$shareRoot/"
    cp -r "$pkgRoot/docs" "$shareRoot/"
    cp -r "$pkgRoot/examples" "$shareRoot/"
    cp -r "$pkgRoot/dist" "$shareRoot/"
  '';

  postFixup = ''
    wrapProgram $out/bin/pi \
      --prefix PATH : ${lib.makeBinPath [fd ripgrep]} \
      --set-default PI_PACKAGE_DIR "$out/share/pi-coding-agent"
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = ["HOME"];
  versionCheckProgram = "${placeholder "out"}/bin/pi";
  versionCheckProgramArg = "--version";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://shittycodingagent.ai/";
    downloadPage = "https://www.npmjs.com/package/@mariozechner/pi-coding-agent";
    changelog = "https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "pi";
  };
})
