#!/usr/bin/env bash

function main() {
    ########################################
    header "Introduction" "Hello there"
    ########################################
    echo "This script installs programs and sets up the configurations on you machine."
    echo "It is idempotent so it can be run multiple times without causing issues."
    echo "In the beginning there might be some things which require user interaction, so beware."
    echo "I will tell you as soon as you can lay back."


    ########################################
    header "Prescript" "Downloading dotfiles repository from GitHub"
    ########################################

    # Command Line Tools
    xcode-select -p > /dev/null 2>&1
    if [[ $? != 0 ]]; then
        info "Installing Command Line Tools"
        info "This will prompt you with a software update pop-up, simply press \"Install\""
        xcode-select --install
        read -p "Wait for the installation to finish, then press [ENTER] to continue..."
        ok
    fi

    git clone git@github.com:martyer/dotfiles.git

    echo
    ########################################
    header "Installation" "Checking Homebrew installation"
    ########################################

    # Installing Homebrew
    which brew > /dev/null 2>&1
    if [[ $? != 0 ]]; then
        info "Installing Homebrew"
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        if [[ $? != 0 ]]; then
          error "Unable to install Homebrew"
          exit 1
        fi
        ok
    fi

    # Updating Homebrew
    info "Updating Homebrew"
    brew update
    ok

    # Updating packages
    info "Updating packages"
    brew upgrade
    ok


    echo
    ########################################
    header "Configuration" "Defaults write"
    ########################################

    source ./defaults.sh


    # Setting git user name und email address
    if [[ ! -f ~/.gitconfig  ]]; then
        info "Setting git user name and email address"
        while [[ "$response" != "Y" ]]; do
            read -r -p "Please enter your full name to be used by git: [e.g. Linus Torvalds]: " fullname
            read -r -p "Please enter your email address to be used by git: [e.g. linus@torvalds.com]: " email
            echo -e "I got the name \"$fullname\" and the email address \"$email\""
            read -r -p "Is this correct? [Y|n] " response
        done

        git config --global user.name "$fullname"
        git config --global user.email "$email"
    fi



    # TODO add the private keys to PWManager
}

################################################################################
# Helper functions for beautified console output

function header() {
    # Bold
    echo -e "\033[1m$1\033[0m - $2"
}

function info() {
    # Blue and Bold
    echo -e "\033[34;1m[INFO]\033[0m $1"
}

function ok() {
    # Green and Bold
    echo -e "\033[32;1m[OK]\033[0m $1"
}

function warn() {
    # Yellow and Bold
    echo -e "\033[33;1m[WARN]\033[0m $1"
}

function error() {
    # Red and Bold
    echo -e "\033[31;1m[ERROR]\033[0m $1"
}
################################################################################

function brew_install_or_upgrade {
    if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" > /dev/null); then
        echo "Upgrading already installed package $1 ..."
        brew upgrade "$1"
    else
        echo "Latest $1 is already installed"
    fi
    else
    brew install "$1"
    fi
}

main "$@"