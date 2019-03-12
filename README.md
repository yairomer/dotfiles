# Dotfiles

My dotfiles.

## The dotcli script

An auxiliary CLI tool to setup and remove the dotfiles.

### Usage

From the output of *./dotcli -h*:
See *./dotcli.sh -h* for all available options.

``` text
A CLI tool to setup dotfiles configurations

usage: dotcli  <command> [<options>]
   or: dotcli -h         to print this help message.

Commands
    run                     Run a list of setup stages.
    switch_to_ssh           Switch dotfiles repository's upstream to be SSH based.
    clean_up                Restore the backed up dotfiles.
Use dotcli <command> -h for specific help on each command.
```

### Common usages

- Full setup:

``` bash
./dotcli run -a
```

- Only link dotfiles

``` bash
./dotcli run link_dotfiles
```

- Remove link to dotfiles

``` bash
./dotcli clean_up
```
