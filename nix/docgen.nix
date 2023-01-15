{pkgs, ...}:
pkgs.writeShellApplication {
  name = "ht-generate-docs";
  runtimeInputs = with pkgs; [
    lemmy-help
  ];
  text = ''
    lemmy-help lua/haskell-tools/{init,config,log,lsp,hoogle,repl,project,tags}.lua lua/telescope/_extensions/ht.lua > doc/haskell-tools.txt
  '';
}
