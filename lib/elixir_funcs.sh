function download_elixir() {
  fix_elixir_version

  # If a previous download does not exist, then always re-download
  if [ ${force_fetch} = true ] || [ ! -f ${cache_path}/$(elixir_download_file) ]; then
    clean_elixir_downloads
    elixir_changed=true

    output_section "Downloading Elixir"

    local download_url="http://s3.hex.pm/builds/elixir/${elixir_version}.zip"
    curl -ksL ${download_url} -o ${cache_path}/$(elixir_download_file) || exit 1
  else
    output_section "[skip] Already downloaded Elixir ${elixir_version}"
  fi
}


function install_elixir() {
  output_section "Installing Elixir ${elixir_version}"

  mkdir -p $(elixir_path)
  cd $(elixir_path)
  jar xf ${cache_path}/$(elixir_download_file)
  cd - > /dev/null

  chmod +x $(elixir_path)/bin/*
  PATH=$(elixir_path)/bin:${PATH}

  export LC_CTYPE=en_US.utf8
  export MIX_ENV=prod
}


function fix_elixir_version() {
  if [ ${#elixir_version[@]} -eq 2 ] && [ ${elixir_version[0]} = "branch" ]; then
    force_fetch=true
    elixir_version=${elixir_version[1]}

  elif [ ${#elixir_version[@]} -eq 1 ]; then
    # If we detect a version string (ex: 0.15.1) we prefix it with "v"
    if [[ ${elixir_version} =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
      elixir_version=v${elixir_version}
    fi

  else
    output_line "Invalid Elixir version specified"
    output_line "See the README for allowed formats at:"
    output_line "https://github.com/HashNuke/heroku-buildpack-elixir"
    exit 1
  fi
}


function elixir_download_file() {
  echo elixir-${elixir_version}.zip
}


function clean_elixir_downloads() {
  rm -rf ${cache_path}/elixir*.zip
}


function restore_mix() {
  if [ -d $(mix_backup_path) ]; then
    cp -R $(mix_backup_path) ${HOME}/.mix
  fi

  if [ -d $(hex_backup_path) ]; then
    cp -R $(hex_backup_path) ${HOME}/.hex
  fi
}


function backup_mix() {
  # Delete the previous backups
  rm -rf $(mix_backup_path) $(hex_backup_path)

  cp -R ${HOME}/.mix $(mix_backup_path)
  cp -R ${HOME}/.hex $(hex_backup_path)
}

function install_hex() {
  output_section "Installing Hex"
  if [ -z ${hex_source} ]; then
    mix local.hex --force
  else
    mix archive.install ${hex_source} --force
  fi
}


function install_rebar() {
  output_section "Installing rebar"

  # The --force flag was added in Elixir 0.15.2
  # Remove the 'if' when most users have migrated
  # away from 0.15.1 and earlier version

  if [ ! -f ${HOME}/.mix/rebar ]; then
    mix local.rebar --force
  fi
}
