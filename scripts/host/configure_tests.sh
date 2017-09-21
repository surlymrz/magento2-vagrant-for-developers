#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && vagrant_dir=$PWD

source "${vagrant_dir}/scripts/output_functions.sh"

status "Creating configuration for Magento Tests"
incrementNestingLevel

magento_tests_root="${vagrant_dir}/magento/dev/tests"
magento_host_name="$(bash "${vagrant_dir}/scripts/get_config_value.sh" "magento_host_name")"
magento_admin_frontname="$(bash "${vagrant_dir}/scripts/get_config_value.sh" "magento_admin_frontname")"
magento_admin_user="$(bash "${vagrant_dir}/scripts/get_config_value.sh" "magento_admin_user")"
magento_admin_password="$(bash "${vagrant_dir}/scripts/get_config_value.sh" "magento_admin_password")"

# Unit tests
if [[ ! -f "${magento_tests_root}/unit/phpunit.xml" ]] && [[ -f "${magento_tests_root}/unit/phpunit.xml.dist" ]]; then
    status "Creating configuration for Unit tests"
    cp "${magento_tests_root}/unit/phpunit.xml.dist" "${magento_tests_root}/unit/phpunit.xml"
fi

# Integration tests
if [[ ! -f "${magento_tests_root}/integration/phpunit.xml" ]] && [[ -f "${magento_tests_root}/integration/phpunit.xml.dist" ]]; then
    status "Creating configuration for Integration tests"
    cp "${magento_tests_root}/integration/phpunit.xml.dist" "${magento_tests_root}/integration/phpunit.xml"
    sed -i.back "s|<const name=\"TESTS_CLEANUP\" value=\"enabled\"/>|<const name=\"TESTS_CLEANUP\" value=\"disabled\"/>|g" "${magento_tests_root}/integration/phpunit.xml"
    rm -f "${magento_tests_root}/integration/phpunit.xml.back"

    if [[ ! -f "${magento_tests_root}/integration/etc/install-config-mysql.php" ]] && [[ -f "${magento_tests_root}/integration/etc/install-config-mysql.php.dist" ]]; then
        cp "${magento_tests_root}/integration/etc/install-config-mysql.php.dist" "${magento_tests_root}/integration/etc/install-config-mysql.php"
        sed -i.back "s|'db-password' => '123123q'|'db-password' => ''|g" "${magento_tests_root}/integration/etc/install-config-mysql.php"
        sed -i.back "s|\];|\\
    'amqp-host' => 'localhost',\\
    'amqp-port' => '5672',\\
    'amqp-user' => 'guest',\\
    'amqp-password' => 'guest'\\
];|g" "${magento_tests_root}/integration/etc/install-config-mysql.php"
        rm -f "${magento_tests_root}/integration/etc/install-config-mysql.php.back"
    fi
fi

# Web API tests (api-functional)
if [[ ! -f "${magento_tests_root}/api-functional/rest.xml" ]] && [[ -f "${magento_tests_root}/api-functional/phpunit.xml.dist" ]]; then
    status "Creating configuration for REST tests"
    cp "${magento_tests_root}/api-functional/phpunit.xml.dist" "${magento_tests_root}/api-functional/rest.xml"
    sed -i.back "s|http://magento.url|http://${magento_host_name}|g" "${magento_tests_root}/api-functional/rest.xml"
    sed -i.back "s|http://magento-ee.localhost|http://${magento_host_name}|g" "${magento_tests_root}/api-functional/rest.xml"
    sed -i.back "s|<const name=\"TESTS_CLEANUP\" value=\"enabled\"/>|<const name=\"TESTS_CLEANUP\" value=\"disabled\"/>|g" "${magento_tests_root}/api-functional/rest.xml"
    rm -f "${magento_tests_root}/api-functional/rest.xml.back"
fi
if [[ ! -f "${magento_tests_root}/api-functional/soap.xml" ]] && [[ -f "${magento_tests_root}/api-functional/phpunit.xml.dist" ]]; then
    status "Creating configuration for SOAP tests"
    cp "${magento_tests_root}/api-functional/phpunit.xml.dist" "${magento_tests_root}/api-functional/soap.xml"
    sed -i.back "s|http://magento.url|http://${magento_host_name}|g" "${magento_tests_root}/api-functional/soap.xml"
    sed -i.back "s|http://magento-ee.localhost|http://${magento_host_name}|g" "${magento_tests_root}/api-functional/soap.xml"
    sed -i.back "s|<const name=\"TESTS_WEB_API_ADAPTER\" value=\"rest\"/>|<const name=\"TESTS_WEB_API_ADAPTER\" value=\"soap\"/>|g" "${magento_tests_root}/api-functional/soap.xml"
    sed -i.back "s|<const name=\"TESTS_CLEANUP\" value=\"enabled\"/>|<const name=\"TESTS_CLEANUP\" value=\"disabled\"/>|g" "${magento_tests_root}/api-functional/soap.xml"
    rm -f "${magento_tests_root}/api-functional/soap.xml.back"
fi

# Functional tests
if [[ ! -f "${magento_tests_root}/functional/phpunit.xml" ]] && [[ -f "${magento_tests_root}/functional/phpunit.xml.dist" ]]; then
    status "Creating configuration for Functional tests"
    cp "${magento_tests_root}/functional/phpunit.xml.dist" "${magento_tests_root}/functional/phpunit.xml"
    sed -i.back "s|http://localhost|http://${magento_host_name}|g" "${magento_tests_root}/functional/phpunit.xml"
    sed -i.back "s|/backend/|/${magento_admin_frontname}/|g" "${magento_tests_root}/functional/phpunit.xml"
    rm -f "${magento_tests_root}/functional/phpunit.xml.back"

    if [[ ! -f "${magento_tests_root}/functional/etc/config.xml" ]] && [[ -f "${magento_tests_root}/functional/etc/config.xml.dist" ]]; then
        cp "${magento_tests_root}/functional/etc/config.xml.dist" "${magento_tests_root}/functional/etc/config.xml"
        sed -i.back "s|magento2ce.com|${magento_host_name}|g" "${magento_tests_root}/functional/etc/config.xml"
        sed -i.back "s|admin/|${magento_admin_frontname}/|g" "${magento_tests_root}/functional/etc/config.xml"
        sed -i.back "s|<backendLogin>admin</backendLogin>|<backendLogin>${magento_admin_user}</backendLogin>|g" "${magento_tests_root}/functional/etc/config.xml"
        sed -i.back "s|<backendPassword>123123q</backendPassword>|<backendPassword>${magento_admin_password}</backendPassword>|g" "${magento_tests_root}/functional/etc/config.xml"
        rm -f "${magento_tests_root}/functional/etc/config.xml.back"
    fi
fi

decrementNestingLevel
