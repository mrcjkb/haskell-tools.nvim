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
      mkdir -p $out/.config/nvim/site/pack/packer/start
      ln -s ${packer-nvim} $out/.config/nvim/site/pack/packer/start/packer.nvim
      ln -s ${plenary-nvim} $out/.config/nvim/site/pack/packer/start/plenary.nvim
      ln -s ${nvim-lspconfig} $out/.config/nvim/site/pack/packer/start/nvim-lspconfig
      ln -s ${telescope-nvim} $out/.config/nvim/site/pack/packer/start/telescope.nvim
      ln -s ${./..} $out/.config/nvim/site/pack/packer/start/${name}
    '';

    checkPhase = ''
      export NVIM_DATA_MINIMAL=$(realpath $out/.config/nvim)
      export HOME=$(realpath .)
      cd ${./..}
      nvim --headless --noplugin -u ${../tests/minimal.lua} -c "PlenaryBustedDirectory tests {minimal_init = '${../tests/minimal.lua}'}"
    '';
  };

in
{

  haskell-tools-test = mkPlenaryTest { name = "haskell-tools.nvim"; };

}
