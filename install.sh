#!/usr/bin/env bash

DOTFILES_REPO=~/dotfiles

function main() {
    header "Hello there"
    echo "This script will install programs and set up most of the configuration on your machine."
    echo "It is idempotent so it can be run multiple times without causing issues."
    echo "In the beginning there might be some things which require user interaction, so beware."
    echo "I will tell you as soon as you are not required to pay attention anymore."
    echo

    ask_for_sudo
    install_homebrew

    header "Woop, woop..."
    echo "Now there should be no more user interaction required. You can lay back and relax."
    echo

    clone_dotfiles_repo
    install_packages_with_brewfile
    setup_macOS_defaults
    configure_git

    # TODO add the private keys to PWManager
    # TODO: Add ssh key to keychain
}

function ask_for_sudo() {
    header "Prompting for sudo password"
    # Check if the sudo password is cached and if it is not ask for it
    if sudo --validate; then
        # Reset the sudo timestamp by calling sudo true every minute and repeat that until the main script finished
        while true; do sudo --non-interactive true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
        ok "Sudo credentials acquired"
    else
        error "Obtaining sudo credentials failed"
        exit 1
    fi
    echo
}

function install_homebrew() {
    header "Installing Homebrew"
    if hash brew 2>/dev/null; then
        ok "Homebrew already installed"
    else
        if /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; then
            ok "Homebrew installation succeeded"
        else
            error "Homebrew installation failed"
            exit 1
        fi
    fi
    echo
}

function clone_dotfiles_repo() {
    header "Cloning dotfiles repository into $DOTFILES_REPO"
    if test -e "$DOTFILES_REPO"; then
        info "$DOTFILES_REPO already exists"
        info "Pulling latest changes in $DOTFILES_REPO repository"
        if git -C "$DOTFILES_REPO" pull origin master &> /dev/null; then
            ok "Pull successful in $DOTFILES_REPO repository"
        else
            error "Error while pulling, check the $DOTFILES_REPO repo manually"
            exit 1
        fi
    else
        # Cloning dotfiles repo without having to set credentials
        if git clone "https://github.com/martyer/dotfiles.git" "$DOTFILES_REPO"; then
            ok "Cloned into $DOTFILES_REPO"
        else
            error "Cloning into $DOTFILES_REPO failed"
            exit 1
        fi
    fi
    echo
}

function install_packages_with_brewfile() {
    BREW_FILE="$DOTFILES_REPO/Brewfile"

    header "Installing packages within $BREW_FILE"
    if brew bundle check --file="$BREW_FILE" &> /dev/null; then
        ok "All packages already up to date"
    else
        if brew bundle --file="$BREW_FILE"; then
            ok "Installation of packages succeeded"
        else
            error "Installation of packages failed"
            exit 1
        fi
    fi
    echo
}

function setup_macOS_defaults() {
    DEFAULTS_SCRIPT="$DOTFILES_REPO/defaults.sh"

    header "Updating macOS defaults"
    if source "$DEFAULTS_SCRIPT"; then
        ok "Defaults setup succeeded"
    else
        error "Defaults setup failed"
        exit 1
    fi
    echo
}

function configure_git() {
    header "Configuring git username and email"
    if git config --global --get user.name; then
        ok "Git username already configured"
    else
        while test "$response" != "Y"; do
            read -r -p "Please enter your full name to be used by git: [e.g. Linus Torvalds]: " fullname
            echo -e "I got the name \"$fullname\""
            read -r -p "Is this correct? [Y|n] " response
        done
        git config --global --global user.name "$fullname"
        ok "Git username successfully set"
    fi

    if git config --global --get user.email; then
        ok "Email already configured"
    else
        while test "$response" != "Y"; do
            read -r -p "Please enter your email address to be used by git: [e.g. linus@torvalds.com]: " email
            echo -e "I got the email address \"$email\""
            read -r -p "Is this correct? [Y|n] " response
        done
        git config --global user.email "$email"
        ok "Git email successfully set"
    fi
    echo
}

function add_ssh_key_to_keychain() {
    header "Adding SSH key to keychain"
    ssh-add -K ~/.ssh/[your-private-key]
    echo
}

function header() {
    # Bold
    echo -e "\033[1mʘ‿ʘ\033[0m - $1"
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

main "$@"