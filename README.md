# Vagrant project for Magento 2 EE developers (optimized for \*nix hosts)

 * [About](#about)
 * [What you get](#what-you-get)
 * [How to install](#how-to-install)
   * [Requirements](#requirements)
   * [Installation steps](#installation-steps)
   * [Default credentials and settings](#default-credentials-and-settings)
 * [Day-to-day development scenarios](#day-to-day-development-scenarios)
   * [Reinstall Magento](#reinstall-magento)
   * [Clear Magento cache](#clear-magento-cache)
   * [Use Magento CLI (bin/magento)](#use-magento-cli-binmagento)
   * [Debugging with XDebug](#debugging-with-xdebug)
   * [Connecting to MySQL DB](#connecting-to-mysql-db)
   * [View emails sent by Magento](#view-emails-sent-by-magento)
   * [Accessing PHP and other config files](#accessing-php-and-other-config-files)
   * [Upgrading Magento](#upgrading-magento)
   * [Multiple Magento instances](#multiple-magento-instances)
   * [Update Composer dependencies](#update-composer-dependencies)
 * [Environment configuration](#environment-configuration)
   * [Switch between PHP 5.6 and 7.0](#switch-between-php-56-and-70)
   * [Activating Varnish](#activating-varnish)
   * [Activating ElasticSearch](#activating-elasticsearch)
   * [Redis for caching](#redis-for-caching)
   * [Reset environment](#reset-environment)

## About
This project is a fork of [this project](https://github.com/paliarush/magento2-vagrant-for-developers) and all original credit goes to the author.

My goal was to take the framework of this project and strip it down: simplify it for my needs which were just the Linux platform and Magento Enterprise Edition. It also assumes that you will place your Magento root folder in /magento.

## What you get

It is expected that Magento 2 project source code will be located and managed on the host. This is necessary to allow quick indexing of project files by IDE. All other infrastructure is deployed on the guest machine.

Current Vagrant configuration aims to solve performance issues of Magento installed on VirtualBox **for development**.

It is easy to [install multiple Magento instances](#multiple-magento-instances) based on different codebases simultaneously.

[Project initialization script](init_project.sh) configures complete development environment:

 1. Adds some missing software on the host
 1. Configures all software necessary for Magento 2 using [custom Ubuntu vagrant box](https://atlas.hashicorp.com/paliarush/boxes/magento2.ubuntu) (Apache 2.4, PHP 7.0 (or 5.6), MySQL 5.6, Git, Composer, XDebug, Rabbit MQ, Varnish)
 1. Configures PHPStorm project (partially at the moment)
 1. Installs NodeJS, NPM, Grunt and Gulp for front end development
 
## How to install

If you've never used Vagrant before, read [Vagrant Docs](https://docs.vagrantup.com/v2)

### Requirements

Software listed below should be available in [PATH](https://en.wikipedia.org/wiki/PATH_\(variable\)) (except for PHP Storm).

- [Vagrant 1.8+](https://www.vagrantup.com/downloads.html)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git). Make sure you have SSH keys generated and associated with your github account, see [how to check](https://help.github.com/articles/testing-your-ssh-connection/) and [how to configure](https://help.github.com/articles/generating-ssh-keys/) if not configured.<br />

    ```
    git config --global core.autocrlf false
    git config --global core.eol LF
    git config --global diff.renamelimit 5000
    ```
- [PHP](http://php.net/manual/en/install.php) (any version) to allow Magento dependency management with [Composer](https://getcomposer.org/doc/00-intro.md)
- [PhpStorm](https://www.jetbrains.com/phpstorm) is optional but recommended.
- [NFS server](https://en.wikipedia.org/wiki/Network_File_System) must be installed and running on \*nix and OSX hosts. Is usually available, so just try to follow [installation steps](#how-to-install) first.

### Installation steps

 1. Optionally, copy [etc/config.yaml.dist](etc/config.yaml.dist) as `etc/config.yaml` and make necessary customizations

 1. Initialize project (this will configure environment, install Magento, configure PHPStorm project):

   ```
   cd vagrant-magento
   bash init_project.sh
   ```

 1. Use `vagrant-magento` directory as project root in PhpStorm (not `vagrant-magento/magento`). This is important, because in this case PhpStorm will be configured automatically by [init_project.sh](init_project.sh). If NFS files sync is disabled in [config](etc/config.yaml.dist) and on Windows hosts [verify deployment configuration in PhpStorm](docs/phpstorm-configuration-windows-hosts.md)

 1. Configure remote PHP interpreter in PhpStorm. Go to `Settings => Languages & Frameworks => PHP`, add new remote interpreter and select "Deployment configuration" as a source for connection details.

### Default credentials and settings

Some of default settings are available for override. These settings can be found in the file [etc/config.yaml.dist](etc/config.yaml.dist).
To override settings just create a copy of the file under the name 'config.yaml' and put there your custom settings.
When using [init_project.sh](init_project.sh), if not specified manually, random IP address is generated and is used as suffix for host name to prevent collisions, in case when 2 or more instances are running at the same time.
Upon a successful installation, you'll see the location and URL of the newly-installed Magento 2 application in console.

**Web access**:
- Access storefront at `http://magento2.vagrant<random_suffix>`
- Access admin panel at `http://magento2.vagrant<random_suffix>/admin/`
- Magento admin user/password: `admin/123123q`
- Rabbit MQ control panel: `http://magento2.vagrant<random_suffix>:15672`, credentials `guest`/`guest`

**Codebase and DB access**:
- Path to your Magento installation on the VM:
  - Can be retrieved from environment variable: `echo ${MAGENTO_ROOT}`
  - On Windows hosts: `/var/www/magento`
  - On Mac and \*nix hosts: the same as on host
- MySQL DB host: `localhost` (may require configuration change to access remotely)
- MySQL DB name: `magento`, `magento_integration_tests`
- MySQL DB user/password: `root:<no password>`. In CLI just use `mysql` with no user and password (`root:<no password>` will be used by default)

**Codebase on host**
- `vagrant_project_root/magento`

## Day-to-day development scenarios

### Reinstall Magento

If no composer update is necessary, use the following command. It will clear Magento DB, Magento caches and reinstall Magento instance.

Go to the root of vagrant project in command line and execute:

```
bash m-reinstall
```

### Clear Magento cache

Go to the root of vagrant project in command line and execute:

```
bash m-clear-cache
```

### Use Magento CLI (bin/magento)

Go to 'vagrant-magento' created earlier and run in command line:

```
bash m-bin-magento <command_name>
e.g.
bash m-bin-magento list
```

### Debugging with XDebug

XDebug is already configured to connect to the host machine automatically. So just:

 1. Set XDEBUG_SESSION=1 cookie (e.g. using 'easy Xdebug' extension for Firefox). See [XDebug documentation](http://xdebug.org/docs/remote) for more details
 1. Start listening for PHP Debug connections in PhpStorm on default 9000 port. See how to [integrate XDebug with PhpStorm](https://www.jetbrains.com/phpstorm/help/configuring-xdebug.html#integrationWithProduct)
 1. Set beakpoint or set option in PhpStorm menu 'Run -> Break at first line in PHP scripts'

To debug a CLI script:

 1. Create [remote debug configuration](https://www.jetbrains.com/help/phpstorm/2016.1/run-debug-configuration-php-remote-debug.html) in PhpStorm, use `phpstorm` as IDE key
 1. Run created remote debug configuration
 1. Run CLI command on the guest as follows (`xdebug.remote_host` value might be different for you):

 ```
 php -d xdebug.remote_autostart=1 <path_to_cli_script>
 ```

To debug Magento Setup script, go to [Magento installation script](scripts/guest/m-reinstall) and find `php ${install_cmd}`. Follow steps above for any CLI script

:information_source: In addition to XDebug support, [config.yaml](etc/config.yaml.dist) has several options in `debug` section which allow storefront and admin UI debugging. Plus, desired Magento mode (developer/production/default) can be enabled using `magento_mode` option, default is developer mode.

### Connecting to MySQL DB

Coming soon.

### View emails sent by Magento

All emails are saved to 'vagrant-magento/log/email' in HTML format.

### Accessing PHP and other config files

It is possible to view/modify majority of guest machine config files directly from IDE on the host. They will be accessible in [etc/guest](etc/guest) directory only when guest machine is running. The list of accessible configs includes: PHP, Apache, Mysql, Varnish, RabbitMQ.
Do not edit any symlinks using PhpStorm because it may break your installation.

After editing configs in IDE it is still required to restart related services manually.

### Multiple Magento instances

To install several Magento instances based on different code bases, just follow [Installation steps](#installation-steps) to initialize project in another directory on the host.
Unique IP address, SSH port and domain name will be generated for each new instance if not specified manually in `etc/config.yaml`

### Update Composer dependencies

Go to 'vagrant-magento' created earlier and run in command line:

```
bash m-composer install
OR
bash m-composer update
```

## Environment configuration

### Switch between PHP 5.6 and 7.0

Set "use_php7: 1" for PHP7 and "use_php7: 0" for PHP5.6 in [config.yaml](etc/config.yaml.dist).
PHP version will be applied after "vagrant reload".

### Activating Varnish

Set `use_varnish: 1` to use varnish along apache in [config.yaml](etc/config.yaml.dist). Changes will be applied on `m-reinstall`.
It will use default file etc/magento2_default_varnish.vcl.dist generated from a Magento instance.
Varnish Version: 3.0.5

Use the following commands to enable/disable varnish without reinstalling Magento: `m-varnish disable` or `m-varnish enable`.

### Activating ElasticSearch

:information_source: Available in Magento EE only.

Set `search_engine: "elasticsearch"` in [config.yaml](etc/config.yaml.dist) to use ElasticSearch as current search engine or `search_engine: "mysql"` to use MySQL. Changes will be applied on `m-reinstall`.

Use the following commands to switch between search engines without reinstalling Magento: `m-search-engine elasticsearch` or `m-search-engine mysql`.

### Redis for caching

:information_source: Available in Magento v2.0.6 and higher.

Redis is configured as cache backend by default. It is still possible to switch back to filesystem cache by changing `environment_cache_backend` to `filesystem` in [config.yaml](etc/config.yaml.dist).

### Reset environment

It is possible to reset project environment to default state, which you usually get just after project initialization. The following command will delete vagrant box and vagrant project settings. After that it will initialize project from scratch. Magento 2 code base (`magento` directory) and [etc/config.yaml](etc/config.yaml.dist) and PhpStorm settings will stay untouched, but guest config files (located in [etc/guest](etc/guest)) will be cleared.

Go to 'vagrant-magento' created earlier and run in command line:

```
bash init_project.sh -f
```

To reset PhpStorm project configuration, in addition to `-f` specify `-p` option:

```
bash init_project.sh -fp
```
