{pkgs, ...}:
pkgs.writeShellApplication {
  name = "docgen";
  runtimeInputs = with pkgs; [
    lemmy-help
  ];
  text = ''
    mkdir -p doc
    lemmy-help lua/haskell-tools/{init,config/init,lsp/init,dap/init,hoogle/init,repl/init,project/init,tags,log/init}.lua lua/telescope/_extensions/ht.lua > doc/haskell-tools.txt
  '';
}
