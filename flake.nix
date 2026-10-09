{
  description = "wwn-gtk: Wawona's GTK4 port (GDK Wayland + GSK) and gtk4-demo across Apple platforms and Android. Cairo/wl_shm first; GL where allowGpu. Shared foundation for wwn-gnome / wwn-gtkgreet / wwn-gtklock. SCAFFOLD: real recipes are downstream.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    wwn-toolchain.url = "github:Wawona/wwn-toolchain";
    wwn-toolchain.inputs.nixpkgs.follows = "nixpkgs";
    wwn-toolchain.inputs.rust-overlay.follows = "rust-overlay";
  };

  outputs = { self, nixpkgs, rust-overlay, wwn-toolchain, ... }:
    let
      darwinSystems = [ "x86_64-darwin" "aarch64-darwin" ];
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      allSystems = darwinSystems ++ linuxSystems;
      forAll = nixpkgs.lib.genAttrs allSystems;
      inherit (wwn-toolchain.lib) withPlatformVariants;

      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) ];
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          android_sdk.accept_license = true;
        };
      };

      gtk4Dir = ./dependencies/gtk4;
      demoDir = ./dependencies/gtk4-demo;
    in
    {
      # Registry fragment merged into Wawona's client registry. Every target
      # points at the stub until the real per-platform recipes land:
      #   android / wearos -> android.nix
      #   ios / ipados / visionos / tvos -> ios.nix (tvos GL behind allowGpu)
      #   macos -> macos.nix
      #   watchos -> watchos.nix (Cairo/wl_shm only; no Metal in the SDK)
      registryFragment = {
        gtk4 = withPlatformVariants {
          android = gtk4Dir + "/stub.nix";
          wearos = gtk4Dir + "/stub.nix";
          ios = gtk4Dir + "/stub.nix";
          ipados = gtk4Dir + "/stub.nix";
          tvos = gtk4Dir + "/stub.nix";
          visionos = gtk4Dir + "/stub.nix";
          watchos = gtk4Dir + "/stub.nix";
          macos = gtk4Dir + "/stub.nix";
        };
        "gtk4-demo" = withPlatformVariants {
          android = demoDir + "/stub.nix";
          wearos = demoDir + "/stub.nix";
          ios = demoDir + "/stub.nix";
          ipados = demoDir + "/stub.nix";
          tvos = demoDir + "/stub.nix";
          visionos = demoDir + "/stub.nix";
          watchos = demoDir + "/stub.nix";
          macos = demoDir + "/stub.nix";
        };
      };

      formatter = forAll (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
