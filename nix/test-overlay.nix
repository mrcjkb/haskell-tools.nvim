{ packer-nvim, plenary-nvim, nvim-lspconfig, telescope-nvim }:
final: prev:
with final.lib;
with final.stdenv;

let
  mkPlenaryTest = { nvim ? final.neovim, name }: mkDerivation {
    inherit name;

    phases = [
      "buildPhase"
      "checkPhase"
    ];

    doCheck = true;

    buildInputs = with final; [
      nvim
      makeWrapper
    ];

    buildPhase = ''
      mkdir -p $out
      mkdir -p .config/nvim/site/pack/packer/start
      ln -s ${packer-nvim} .config/nvim/site/pack/packer/start/packer.nvim
      ln -s ${plenary-nvim} .config/nvim/site/pack/packer/start/plenary.nvim
      ln -s ${nvim-lspconfig} .config/nvim/site/pack/packer/start/nvim-lspconfig
      ln -s ${telescope-nvim} .config/nvim/site/pack/packer/start/telescope.nvim
      ln -s ${./..} .config/nvim/site/pack/packer/start/${name}
    '';

    checkPhase = ''
      export NVIM_DATA_MINIMAL=$(realpath ./.config/nvim)
      export HOME=$(realpath .)
      nvim --headless --noplugin -u ${../tests/minimal.lua} -c "PlenaryBustedDirectory '${../tests}' {minimal_init = '${../tests/minimal.lua}'}"
    '';
  };

in
{

  haskell-tools-test = mkPlenaryTest { name = "haskell-tools.nvim"; };

}
