alias emerge-clean='sudo emerge --ask --depclean; sudo eclean-dist -d'
alias emerge-upgrade='sudo emerge --verbose --ask --update --deep --changed-use --with-bdeps=y @world'

function kernel-upgrade() {
  local current_version="$(uname -r)"
  local selected_version="$(readlink /usr/src/linux | sed 's/^linux-//')"

  if [[ "${current_version}" == "${selected_version}" ]]; then
    echo "The current kernel and the selected kernel are the same."
    echo "Please select a new version of kernel:"
    eselect kernel list
    echo "    eselect kernel set <num>"
    return 1
  fi

  if [[ ! -f "${HOME}/kernel-config/kernel-config-${current_version}" ]]; then
    echo "Save current .config"
    cp -v "/usr/src/linux-${current_version}/.config" "${HOME}/kernel-config/kernel-config-${current_version}"
  fi

  (
    cd /usr/src/linux

    if [[ ! -f ".config" ]]; then
      sudo cp "${HOME}/kernel-config/kernel-config-${current_version}" .config

      echo "* Make new config from current config"
      sudo make silentoldconfig
    fi
  )

  kernel-build
}

function kernel-build() {
  (
    cd /usr/src/linux

    echo "* Prepare modules"
    sudo make modules_prepare

    echo "* Compile kernel"
    sudo make || return 1

    echo "* Install kernel"
    sudo make install

    echo "* Install modules"
    sudo make modules_install
  ) || return 1

  echo "* Rebuild emerged modules"
  sudo emerge --ask @module-rebuild

  echo "* Generate new initramfs"
  sudo genkernel --lvm --install initramfs

  echo "* Update grub.cfg"
  sudo grub-mkconfig -o /boot/grub/grub.cfg

}

function kernel-clean() {
  local current_version="$(uname -r)"

  echo "* Clean /boot"
  sudo find /boot -maxdepth 1 -type f \
    -not -name "*-${current_version}" \
    \( -name 'config-*' -or -name 'initramfs-*' -or -name 'vmlinuz-*' -or -name 'System.map-*' \) \
    -print -delete

  echo "* Clean /lib/modules"
  sudo find /lib/modules -maxdepth 1 -mindepth 1 -not -name "${current_version}" -print -exec rm -rf {} +

  echo "* Update grub.cfg"
  sudo grub-mkconfig -o /boot/grub/grub.cfg

  sudo find /usr/src -maxdepth 1 -type d -name 'linux-*' -not -name "*$(uname -r)" -print -exec rm -rf {} +
}
