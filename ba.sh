	#!/usr/bin/env bash

# This script is used to setup ChromeOs, or Debian 10 Buster, as an Erlang / Elixir / OTP / Phoenix development environment.
# 1) We install asdf version manager for the purpose of managing language and framework versions;
# 2) We use asdf version manager to Install Erlang and Elixir;
# 
#
# TODO: Consider having two functions, e.g. export_required_vars and bashrc_file_changes, these two functions should
# 1) export variables which persist in the system after the script completes, and 2) put required ~/.bashrc entries
# for future program use.
# TODO: Remember after testing, remove the .asdf directory and .bashrc entries to clean up after a test
#
# TODO: Include https in development, refer Programming WebRTC, Serving Https In Development.
 # TODO: Install Rust, investigate preferred method, via asf or using rustup (script)
 # TODO: Install jetbrains-toolbox to enable installation of IntelliJ Idea Ultimate and Android Studio
#
# Backup:
# $ cp Documents/ba.sh /mnt/chromeos/GoogleDrive/MyDrive/bash_scripts/ba.sh
#
set -e
# Ensure that apt package installation is truly quiet and non-interactive
export DEBIAN_FRONTEND=noninterractive;

# Set the framework / library versions to install
ERLANG_VERSION='24.2.1';
ELIXIR_VERSION='1.13.3';
PHOENIX_VERSION='1.6.6';
NODEJS_VERSION='17.5.0';

# Variable Declarations:
INTENT="You are about to setup an Erlang, Elixir / OTP & Phoenix development environment on a ChromeOs Debian based operating system!\n";
MESSAGE="Do you want to proceed with the installation and setup process?";

# NOTIFICATIONS AND STAGES OF SETUP
STEP_1='Adding asdf Version Manager plugins.';
STEP_2="Commencing install of Erlang, go grab a coffee, this will take some time!";
STEP_3="Commencing install of Elixir, hope it's a nice coffee, hang in there!";
STEP_4="Commencing install of node.js, maybe.....grab abother coffee? Not too long to go!";
STEP_5="Installing the Hex package manager! We're almost there!";
STEP_6="Finally, commencing install of Phoenix framework!";
STEP_7="For the pièce de résistance, Sublime Text 4";
STEP_8="The drums are DONE.....Setup completed successfully!";

# upon program error, exit with message to user
on_exit () {
    echo "The installation process did NOT run through to completion!";
}
# set the exit trap
trap on_exit ERR

# yes_or_no is a function to prompt for user feedback to determine if installation is desired.
function yes_or_no {
    while true; do
        read -p "$* [y/n]: " yn
		case $yn in
		    [Yy]*) return 0 
				;;
		    [Nn]*) echo "Installation Aborted" ;
		        return 1 
		        ;;
            [Qq]*) echo "Installation aborted" ;
		        return 1 
		        ;;
		esac
    done
}

# get asdf version manager's current branch version from the asdf-vm web page
function get_asdf_current_version {
    # digit notation (\d) does not work in bash, use [0-9] instead
    URI="https://asdf-vm.com/guide/getting-started.html#_1-install-dependencies";
    REGEX='(git clone https://github.com/asdf-vm/asdf.git )(\~\/\.asdf) (--branch) (v[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2})';
    # retrieve text from web page
    TEXT=`curl "${URI}"`;
    # execute the regex on the returned web page text
    [[ ${TEXT} =~ ${REGEX} ]]
    # return the entire `git clone` line which includes the latest version number of asdf version manager
    echo "${BASH_REMATCH[0]}";
}

# Elixir depends upon Erlang and asdf Version Manager, which is used to install the aforementioned, depends
# upon curl, git and other deps. This function sets up all of those dependencies.
# build-essential is req'd by asdf erlang
function install_required_dependencies {
    echo -e "Installing Elixir dependencies.";
    sudo apt update && sudo apt install -q -y  \
		build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk
	# other dependencies required by asdf or other parts of program
	sudo apt install -q -y \
		apt-transport-https vim curl unzip dirmngr gpg gawk inotify-tools xclip
}

# by adding the required bash entries to .bash_profile we ensure that the variables are available both 
# locally and via remote ssh sessions as appropriate, it is safe to run this script remotely.
function add_bash_profile_entries {
    # add ~/.bash_profile entries
    cat >> ~/.bash_profile <<EOF
# asdf version manager's required entries
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash
EOF
}

# by setting environment vars which determine what documentation is installed with Erlang / Elixir,
# we ensure that docs are installed with this version and future versions.
function set_environment_vars {
    # enable install of erlang docs in dev environments, should not be installed in production environments
    cat >> ~/.bash_profile <<EOF
# ensure current and future documentation will be installed for erlang and elixir with asdf-vm
export KERL_BUILD_DOCS='yes'
EOF
	# by setting KERL_BUILD_DOCS to yes, the HTML & MAN docs are installed by default
	# source the exported var's to ensure available for this install / build
    . ~/.bash_profile
}

# Install Sublime Text as the editor of choice
# TODO: Automate file selection
function install_sublime_text {
	# Install Sublime Text from Stable channel
	wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
	echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
	sudo apt update && sudo apt install -q -y sublime-text
}

# This function is for future use: to check for the existence of files for the purpose of including
# personally signed certificates in the user's home directory, to implement https in development.
# 
# check_file_exists whill check the passed variable ( a file name including extension )
# the function accepts one required parameter, called 'filename', whilst the second parameter
# 'location' is an optional argument with a default value of the currently logged in user's home directory
# e.g. /home/matgarland/  
function check_file_exists {
	file_name=${1:'~/'};
	location=${2:"/home/${USER}/"};
	if [ -f "${location}${file_name}" ]; then
	    return true;
	fi
	return false;
}

# ****** begin script execution ******
echo -e "${INTENT}";
# Prompt user to begin installation process
yes_or_no "${MESSAGE}" && {
    # unzip is required to install Elixir using asdf version manager
    # curl & git required to install asdf version manager
    install_required_dependencies;
    # get the current asdf version manager version from the github repository by scraping the page's contents
    cur_ver=$(get_asdf_current_version);
    # install the latest version of asdf manager
    echo -e "Installing the latest version of asdf version manager";
    # execute the installation of the latest version of asdf version manager
    eval "${cur_ver}";	
    # notify user of success, or otherwise, of the asdf installation 
    if [[ $? -eq 0 ]]; then
		# Installation was successful
    	echo -e 'asdf Version Manager was successfully installed!';
	    echo -e 'Setting environment variables and updating shell profile files!';
		add_bash_profile_entries;
		set_environment_vars;
		echo -e "${STEP_1}";
		# add  Erlang Plugin
		asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
		# add Elixir
		asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git
		# add node.js
		asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
		echo -e "${STEP_2}";
		# install erlang and set global version
		eval "asdf install erlang ${ERLANG_VERSION}";
		eval "asdf global erlang ${ERLANG_VERSION}";
		echo -e "${STEP_3}";
		# install elixir and set global version
		eval "asdf install elixir ${ELIXIR_VERSION}";
		eval "asdf global elixir ${ELIXIR_VERSION}";
		echo -e "${STEP_4}";
		# install nodejs and set global version
		eval "asdf install nodejs ${NODEJS_VERSION}";
		eval "asdf global nodejs ${NODEJS_VERSION}";
		echo -e "${STEP_5}";
		# install Hex package manager, using --force to silently accept installation
		mix local.hex --force
		echo -e "${STEP_6}";
		# install Phoenix Application Generator
		eval "mix archive.install hex phx_new ${PHOENIX_VERSION} --force";
		# Install Sublime Text
		echo -e "${STEP_7}";
		install_sublime_text;
	    echo -e "${STEP_8}";
	    # Exit script with success flag set
	    exit 0;
    else
		# Installation failed
		echo "Installation of asdf Version Manager failed!";
		# exit script due to error
		exit 1;
    fi
}
