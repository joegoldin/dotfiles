# KiCad with its addon and library set pinned by the flake instead of by
# whatever the Plugin and Content Manager last downloaded into ~/.local/share.
#
# Two mechanisms, because KiCad treats the two package kinds differently:
#   plugins   -> kicad.override { addons = [ ... ]; }, which unpacks each PCM
#                zip into the wrapper's stock data path (see ./_kicad/*.nix)
#   libraries -> a 3rdparty tree in the store plus generated global lib tables,
#                which is what the PCM would have written by hand
{ ... }:
{
  den.aspects.kicad.homeManager =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs) unstable;

      # symlinkJoin cannot merge these trees: lndir turns a directory that only
      # one input provides into a symlink, and then refuses to descend into it
      # for the next input ("scripting: is a link instead of a directory"), so
      # every addon after the first is silently dropped -- which is also why
      # upstream kicadAddons never reach the stock data path in nixpkgs 10.0.5.
      # A `cp -rsL` farm dereferences directories and merges properly.
      mergeDirs =
        { name, paths, ... }:
        unstable.runCommand name { } ''
          mkdir -p $out
          for p in ${lib.escapeShellArgs paths}; do
            cp -rsL --no-preserve=mode "$p/." "$out/"
          done
        '';

      callAddon = unstable.kicad.callPackage;

      addons = [
        # AI assistant control of the board over MCP; built from source, since
        # upstream only publishes the PCM zip as a release artifact.
        (callAddon ./_kicad/konnect.nix { })

        # Panelization and fabrication automation. Its symbols and footprints
        # ride along in `libraries` below, where KiCad can actually see them.
        unstable.kicadAddons.kikit

        # Interactive BOM: the standard hand-assembly aid -- one HTML file that
        # cross-highlights BOM rows against the board.
        (callAddon ./_kicad/pcm-plugin.nix {
          pname = "interactive-html-bom";
          version = "2.11.2";
          zip = unstable.fetchurl {
            url = "https://github.com/openscopeproject/InteractiveHtmlBom/releases/download/v2.11.2/InteractiveHtmlBom_v2.11.2_pcm.zip";
            hash = "sha256-vIIgewdTJY2kd5xNZQynFaRE0NjUWjpdjQKxHIYpWn8=";
          };
          description = "Interactive HTML BOM generator for KiCad boards";
          homepage = "https://github.com/openscopeproject/InteractiveHtmlBom";
          license = lib.licenses.mit;
        })

        # One-button JLCPCB output: gerbers, BOM and pick-and-place in the
        # shapes the fab actually accepts.
        (callAddon ./_kicad/pcm-plugin.nix {
          pname = "fabrication-toolkit";
          version = "5.3.1";
          zip = unstable.fetchurl {
            url = "https://github.com/bennymeg/Fabrication-Toolkit/releases/download/5.3.1/Fabrication-Toolkit-5.3.1.zip";
            hash = "sha256-gLBVMciHzKTH2AHGYT4/2+F65eyLgC6HptFsO5oPTEU=";
          };
          description = "JLCPCB fabrication output generator for KiCad";
          homepage = "https://github.com/bennymeg/Fabrication-Toolkit";
          license = lib.licenses.asl20;
        })

        # The fuller JLCPCB assembly workflow: part search against LCSC and
        # the rotation-correction database, where the Fabrication Toolkit above
        # is the one-button export.
        (callAddon ./_kicad/pcm-plugin.nix {
          pname = "jlcpcb-tools";
          version = "2026.04.03";
          zip = unstable.fetchurl {
            url = "https://github.com/bouni/kicad-jlcpcb-tools/releases/download/2026.04.03/KiCAD-PCM-2026.04.03.zip";
            hash = "sha256-6CLm7MgwLQ+E9dyBKbQQT2QEWqopSbZlOzhMaeWE0oQ=";
          };
          description = "LCSC part picker, parts database and JLCPCB assembly outputs";
          homepage = "https://github.com/bouni/kicad-jlcpcb-tools";
          license = lib.licenses.mit;
        })

        # How a part that is in none of the libraries below gets in: imports
        # vendor library downloads into your own symbol and footprint libs.
        (callAddon ./_kicad/pcm-plugin.nix {
          pname = "impart";
          version = "2026.04.07";
          zip = unstable.fetchurl {
            url = "https://github.com/Steffen-W/Import-LIB-KiCad-Plugin/releases/download/2026.04.07/Import-LIB-KiCad-Plugin.zip";
            hash = "sha256-MCB/OUDEqXq7tSP0CgHQI3F9SUT6omCcD44OaWMvXvo=";
          };
          description = "Importer for SnapEDA, Ultra Librarian and EasyEDA library downloads";
          homepage = "https://github.com/Steffen-W/Import-LIB-KiCad-Plugin";
          license = lib.licenses.gpl3Only;
        })

        # Real fonts on silkscreen instead of the stroke font.
        (callAddon ./_kicad/pcm-plugin.nix {
          pname = "kibuzzard";
          version = "1.7.0";
          zip = unstable.fetchurl {
            url = "https://github.com/gregdavill/KiBuzzard/releases/download/1.7.0/KiBuzzard-1.7.0-pcm.zip";
            hash = "sha256-dPp6aIUaXnnq2NgQ+6/Ajb+KM7rhDP9jsX6NMX2+4kQ=";
          };
          description = "Silkscreen text and logo generator using real fonts";
          homepage = "https://github.com/gregdavill/KiBuzzard";
          license = lib.licenses.mit;
        })

        # The document you hand to whoever is soldering the board.
        (callAddon ./_kicad/pcm-plugin.nix {
          pname = "board2pdf";
          version = "1.9.3";
          zip = unstable.fetchurl {
            url = "https://links.dennevi.com/Board2Pdf_v1.9.3.zip";
            hash = "sha256-oaJSyy2wANG40TwnquXII3su2Vfk2vvmHdtJe0VNAkU=";
          };
          description = "Layered assembly and fabrication PDFs from a KiCad board";
          homepage = "https://gitlab.com/dennevi/Board2Pdf";
          license = lib.licenses.gpl3Only;
        })

        # Multi-channel layout: lay out one sheet, copy it to the rest.
        (callAddon ./_kicad/pcm-plugin.nix {
          pname = "replicate-layout";
          version = "5.0.1";
          zip = unstable.fetchurl {
            url = "https://github.com/MitjaNemec/ReplicateLayout/releases/download/5.0.1/ReplicateLayout-5.0.1-pcm.zip";
            hash = "sha256-qjA7xnPdTNApJF2lvTCPsoxRoEgf9Nq2hDV02mTjW+w=";
          };
          description = "Replicate one hierarchical sheet's layout across its repeats";
          homepage = "https://github.com/MitjaNemec/ReplicateLayout";
          license = lib.licenses.gpl2Only;
        })

        # Its companion: arrange the repeated footprints first.
        (callAddon ./_kicad/pcm-plugin.nix {
          pname = "place-footprints";
          version = "5.0.0";
          zip = unstable.fetchurl {
            url = "https://github.com/MitjaNemec/PlaceFootprints/releases/download/5.0.0/PlaceFootprints-5.0.0-pcm.zip";
            hash = "sha256-svnJvUULpqRkRswUDsJYYjLl/+qBEPta3CLPiLo5b18=";
          };
          description = "Place repeated footprints in linear, matrix or circular patterns";
          homepage = "https://github.com/MitjaNemec/PlaceFootprints";
          license = lib.licenses.gpl2Only;
        })

        # Exporter half of the Blender render workflow; the Blender-side
        # addon is installed in Blender, not here.
        (callAddon ./_kicad/pcm-plugin.nix {
          pname = "pcb2blender";
          version = "2.17.1";
          zip = unstable.fetchurl {
            url = "https://github.com/30350n/pcb2blender/releases/download/v2.17.1-k9.0-b4.2lts/pcb2blender_exporter_v2-17-1_k9-0.zip";
            hash = "sha256-FgATO6+lX+Qi6DDKAAAwMOKoKOxdxBy893pAWdDxAME=";
          };
          description = "Exporter feeding the pcb2blender Blender addon for board renders";
          homepage = "https://github.com/30350n/pcb2blender";
          license = lib.licenses.gpl3Only;
        })

        # Ground stitching and board-edge fencing, for the RF and
        # high-speed work.
        (callAddon ./_kicad/pcm-plugin.nix {
          pname = "via-stitching";
          version = "2.0.0";
          zip = unstable.fetchurl {
            url = "https://github.com/jOaSbA/via-stitching/releases/download/v2.0.0/via-stitching-2.0.0.zip";
            hash = "sha256-EpENHcDEFWLCyS6jp+RB0dYNmaGZxfDPn54MtYWKgLQ=";
          };
          description = "Fill zones with stitching vias";
          homepage = "https://github.com/jOaSbA/via-stitching";
          license = lib.licenses.gpl3Only;
        })

        (callAddon ./_kicad/pcm-plugin.nix {
          pname = "viafence";
          version = "1.0.2";
          zip = unstable.fetchurl {
            url = "https://github.com/ozzysv/ViaFence/releases/download/1.0.2/via_fence_1.0.2.zip";
            hash = "sha256-wR2gdFLu3kT2f1xiz4/eh33hSBlukDsDmo+qQdbgjQ4=";
          };
          description = "Generate via fences along tracks and board outlines";
          homepage = "https://github.com/ozzysv/ViaFence";
          license = lib.licenses.gpl3Only;
        })
      ];

      libraries = [
        (unstable.callPackage ./_kicad/pcm-library.nix {
          pname = "kikit";
          inherit (unstable.kicadAddons.kikit-library) version;
          zip = "${unstable.kicadAddons.kikit-library}/addon.zip";
          identifier = "com.github.yaqwsx.kikit-library";
          description = "Symbols and footprints KiKit places when it annotates a panel";
          homepage = "https://github.com/yaqwsx/KiKit";
          license = lib.licenses.mit;
        })

        (unstable.callPackage ./_kicad/pcm-library.nix {
          pname = "espressif";
          version = "3.2.1";
          zip = unstable.fetchurl {
            url = "https://github.com/espressif/kicad-libraries/releases/download/3.2.1/espressif-kicad-addon.zip";
            hash = "sha256-klHZOKLyWtFCSVk4KuMZGLIp0bjp3mNNrX+H5BFbFPk=";
          };
          identifier = "com.github.espressif.kicad-libraries";
          description = "Espressif symbols, footprints and 3D models for KiCad";
          homepage = "https://github.com/espressif/kicad-libraries";
          license = lib.licenses.asl20;
        })

        (unstable.callPackage ./_kicad/pcm-library.nix {
          pname = "arduino";
          version = "4.2.0";
          zip = unstable.fetchurl {
            url = "https://github.com/Alarm-Siren/arduino-kicad-library/releases/download/v4.2.0/arduino-kicad-library-4.2.0-pcm.zip";
            hash = "sha256-Pkf0ZNMmtMR1LUoMcluS7FccYdeyDY9tj2VOJjSa/1Y=";
          };
          identifier = "com.github.alarm-siren.arduino-kicad-library";
          description = "Arduino board symbols and shield footprints for KiCad";
          homepage = "https://github.com/Alarm-Siren/arduino-kicad-library";
          license = lib.licenses.cc-by-sa-40;
        })

        (unstable.callPackage ./_kicad/pcm-library.nix {
          pname = "alternate-kicad-library";
          version = "4.0.1";
          zip = unstable.fetchurl {
            url = "https://github.com/DawidCislo/Alternate-KiCad-Library/releases/download/v4.0n/com_github_alternate_kicad_library.zip";
            hash = "sha256-5yN7YaiWOE+OVPkI1Zjz49/sg8HL6yqNcp53GzUS/ek=";
          };
          identifier = "com.github.dawidcislo.alternate-kicad-library";
          description = "Alternate symbol and footprint set with denser, more uniform drawings";
          homepage = "https://github.com/DawidCislo/Alternate-KiCad-Library";
          license = lib.licenses.cc-by-sa-40;
        })
      ];

      thirdParty = mergeDirs {
        name = "kicad-3rdparty";
        paths = map (p: "${p}/share/kicad/3rdparty") libraries;
      };

      kicadWithAddons = unstable.kicad.override {
        inherit addons;
        symlinkJoin = mergeDirs;
      };

      # KiCad resolves ${KICAD10_3RD_PARTY} inside lib tables and inside the
      # 3D-model paths the library footprints carry, and picks the value up
      # from the environment the same way nixpkgs already feeds it
      # KICAD10_SYMBOL_DIR and friends.
      kicad = unstable.symlinkJoin {
        name = "kicad-${kicadWithAddons.version}-3rdparty";
        paths = [ kicadWithAddons ];
        nativeBuildInputs = [ unstable.makeWrapper ];
        postBuild = ''
          for exe in $out/bin/*; do
            wrapProgram "$exe" --set-default KICAD10_3RD_PARTY ${thirdParty}
          done
        '';
      };

      # The global tables KiCad would otherwise let the PCM edit. The stock
      # libraries stay in via the nested "KiCad" table entry, exactly as in the
      # file KiCad writes on first run; ours are appended with the PCM_ nickname
      # prefix the PCM itself uses.
      libTable =
        {
          kind,
          root,
          glob,
        }:
        unstable.runCommand "kicad-${kind}" { } ''
          {
            echo '(${builtins.replaceStrings [ "-" ] [ "_" ] kind}'
            echo '  (version 7)'
            echo '  (lib (name "KiCad") (type "Table") (uri "''${KICAD10_TEMPLATE_DIR}/${kind}") (options "") (descr "KiCad Default Libraries"))'
            for path in ${thirdParty}/${root}/*/${glob}; do
              [ -e "$path" ] || continue
              id="$(basename "$(dirname "$path")")"
              nick="$(basename "$path" | sed 's/\.[^.]*$//')"
              echo "  (lib (name \"PCM_$nick\") (type \"KiCad\") (uri \"\''${KICAD10_3RD_PARTY}/${root}/$id/$(basename "$path")\") (options \"\") (descr \"\"))"
            done
            echo ')'
          } > $out
        '';
    in
    {
      home.packages = [ kicad ];

      # Managed tables are read-only, so libraries are added here rather than in
      # Preferences > Manage Symbol Libraries. Project-local tables are
      # untouched and stay editable. The 10.0 in the path and the KICAD10_ in
      # the variable names both follow the kicad major version.
      home.file.".config/kicad/10.0/sym-lib-table".source = libTable {
        kind = "sym-lib-table";
        root = "symbols";
        glob = "*.kicad_sym";
      };
      home.file.".config/kicad/10.0/fp-lib-table".source = libTable {
        kind = "fp-lib-table";
        root = "footprints";
        glob = "*.pretty";
      };
    };
}
