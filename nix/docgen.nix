{pkgs, ...}:
pkgs.writeShellApplication {
  name = "docgen";
  runtimeInputs = with pkgs; [
    lemmy-help
  ];
  text = ''
    mkdir -p doc
    lemmy-help lua/haskell-tools/{init,config,lsp,dap,hoogle,repl,project,tags,log}.lua lua/telescope/_extensions/ht.lua > doc/haskell-tools.txt
  '';
}
