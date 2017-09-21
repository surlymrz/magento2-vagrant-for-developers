#!/usr/bin/env bash

set -e

vagrant_dir=$PWD

source "${vagrant_dir}/scripts/output_functions.sh"
resetNestingLevel
current_script_name=`basename "$0"`
initLogFile ${current_script_name}

debug_vagrant_project="$(bash "${vagrant_dir}/scripts/get_config_value.sh" "debug_vagrant_project")"
if [[ ${debug_vagrant_project} -eq 1 ]]; then
    set -x
fi

config_path="${vagrant_dir}/etc/config.yaml"
if [[ ! -f "${config_path}" ]]; then
    status "Initializing etc/config.yaml using defaults from etc/config.yaml.dist"
    cp "${config_path}.dist" "${config_path}"
fi

magento_ee_dir="${vagrant_dir}/magento"
host_os="$(bash "${vagrant_dir}/scripts/host/get_host_os.sh")"
use_nfs="$(bash "${vagrant_dir}/scripts/get_config_value.sh" "guest_use_nfs")"

bash "${vagrant_dir}/scripts/host/check_requirements.sh"

status "Installing missing vagrant plugins"
vagrant_plugin_list="$(vagrant plugin list)"
if ! echo ${vagrant_plugin_list} | grep -q 'vagrant-hostmanager' ; then
    vagrant plugin install vagrant-hostmanager
fi
if ! echo ${vagrant_plugin_list} | grep -q 'vagrant-vbguest' ; then
    vagrant plugin install vagrant-vbguest
fi
if ! echo ${vagrant_plugin_list} | grep -q 'vagrant-host-shell' ; then
    vagrant plugin install vagrant-host-shell
fi

status "Generating random IP address, and host name to prevent collisions (if no custom values specified)"
random_ip="$(( ( RANDOM % 240 )  + 12 ))"
forwarded_ssh_port="$(( random_ip + 3000 ))"
sed -i.back "s|ip_address: \"192.168.10.2\"|ip_address: \"192.168.10.${random_ip}\"|g" "${config_path}"
sed -i.back "s|host_name: \"magento2.vagrant2\"|host_name: \"magento2.vagrant${random_ip}\"|g" "${config_path}"
sed -i.back "s|forwarded_ssh_port: 3000|forwarded_ssh_port: ${forwarded_ssh_port}|g" "${config_path}"
rm -f "${config_path}.back"

# Clean up the project before initialization if "-f" option was specified.
force_project_cleaning=0
force_phpstorm_config_cleaning=0
while getopts 'fp' flag; do
  case "${flag}" in
    f) force_project_cleaning=1 ;;
    p) force_phpstorm_config_cleaning=1 ;;
    *) error "Unexpected option" && exit 1;;
  esac
done
if [[ ${force_project_cleaning} -eq 1 ]]; then
    status "Cleaning up the project before initialization since '-f' option was used"
    vagrant destroy -f 2> >(logError) > >(log)
    mv "${vagrant_dir}/etc/guest/.gitignore" "${vagrant_dir}/etc/.gitignore.back"
    rm -rf "${vagrant_dir}/.vagrant" "${vagrant_dir}/etc/guest"
    mkdir "${vagrant_dir}/etc/guest"
    mv "${vagrant_dir}/etc/.gitignore.back" "${vagrant_dir}/etc/guest/.gitignore"
fi

status "Installing Magento dependencies via Composer"
cd "${magento_ee_dir}"
bash "${vagrant_dir}/scripts/host/composer.sh" install

status "Initializing vagrant box"
cd "${vagrant_dir}"

vagrant up --provider virtualbox 2> >(logError) | {
  while IFS= read -r line
  do
    filterVagrantOutput "${line}"
    lastline="${line}"
  done
  filterVagrantOutput "${lastline}"
}

bash "${vagrant_dir}/scripts/host/check_mounted_directories.sh"

if [[ ${force_project_cleaning} -eq 1 ]] && [[ ${force_phpstorm_config_cleaning} -eq 1 ]]; then
    status "Resetting PhpStorm configuration since '-p' option was used"
    rm -rf "${vagrant_dir}/.idea"
fi
if [[ ! -f "${vagrant_dir}/.idea/deployment.xml" ]]; then
    bash "${vagrant_dir}/scripts/host/configure_php_storm.sh"
fi
bash "${vagrant_dir}/scripts/host/configure_tests.sh"

status "Installing Magento"
bash "${vagrant_dir}/scripts/host/m_reinstall.sh" 2> >(logError)

success "Project initialization succesfully completed (make sure there are no errors in the log above)"

info "$(bold)[Important]$(regular)
    Please use $(bold)${vagrant_dir}$(regular) directory as PhpStorm project root, NOT $(bold)${magento_ee_dir}$(regular)."

if [[ ${host_os} == "Windows" ]] || [[ ${use_nfs} == 0 ]]; then
    info "$(bold)[Optional]$(regular)
    To verify that deployment configuration for $(bold)${magento_ce_dir}$(regular) in PhpStorm is correct,
        use instructions provided here: $(bold)https://github.com/paliarush/magento2-vagrant-for-developers/blob/2.0/docs/phpstorm-configuration-windows-hosts.md$(regular).
    If not using PhpStorm, you can set up synchronization using rsync"
fi

info "$(regular)See details in $(bold)${vagrant_dir}/log/${current_script_name}.log$(regular). For debug output set $(bold)debug:vagrant_project$(regular) to $(bold)1$(regular) in $(bold)etc/config.yaml$(regular)"
