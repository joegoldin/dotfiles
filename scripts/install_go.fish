#!/usr/bin/env fish

function install_go
    set -e

    set VERSION "1.22.3"
    set GOROOT "$argv[1]/.go"
    set GOPATH "$argv[1]/go"
    set OS (uname -s)
    set ARCH (uname -m)

    switch $OS
        case "Linux"
            switch $ARCH
                case "x86_64"
                    set ARCH "amd64"
                case "aarch64"
                    set ARCH "arm64"
                case "armv6" "armv7l"
                    set ARCH "armv6l"
                case "armv8"
                    set ARCH "arm64"
                case "i686" "*386*"
                    set ARCH "386"
            end
            set PLATFORM "linux-$ARCH"
        case "Darwin"
            switch $ARCH
                case "x86_64"
                    set ARCH "amd64"
                case "arm64"
                    set ARCH "arm64"
            end
            set PLATFORM "darwin-$ARCH"
    end

    set shell_profile "$__fish_config_dir/config.fish"

    if [ -d "$GOROOT" ]
        echo "The Go install directory ($GOROOT) already exists. Exiting."
        return
    end

    set PACKAGE_NAME "go$VERSION.$PLATFORM.tar.gz"
    set TEMP_DIRECTORY (mktemp -d)

    echo "Downloading $PACKAGE_NAME ..."
    if type -q wget
        wget https://storage.googleapis.com/golang/$PACKAGE_NAME -O "$TEMP_DIRECTORY/go.tar.gz"
    else
        curl -o "$TEMP_DIRECTORY/go.tar.gz" https://storage.googleapis.com/golang/$PACKAGE_NAME
    end

    if [ $status -ne 0 ]
        echo "Download failed! Exiting."
        return
    end

    echo "Extracting File..."
    mkdir -p "$GOROOT"
    tar -C "$GOROOT" --strip-components=1 -xzf "$TEMP_DIRECTORY/go.tar.gz"

    echo "Configuring shell profile in: $shell_profile"
    touch "$shell_profile"
    echo -e '\n# GoLang' >> "$shell_profile"
    echo "set GOROOT '$GOROOT'" >> "$shell_profile"
    echo "set GOPATH '$GOPATH'" >> "$shell_profile"
    echo 'fish_add_path $GOPATH/bin' >> "$shell_profile"
    echo 'fish_add_path $GOROOT/bin' >> "$shell_profile"

    mkdir -p "$GOPATH/src" "$GOPATH/pkg" "$GOPATH/bin"
    echo -e "\nGo $VERSION was installed into $GOROOT.\nMake sure to run:\n\n\tsource $shell_profile\n\nto update your environment variables."
    rm -f "$TEMP_DIRECTORY/go.tar.gz"
end
