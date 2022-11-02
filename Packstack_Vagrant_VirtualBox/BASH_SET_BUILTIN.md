# Bash set builtin

Shell scripts with `set` options, for example: 

`#!/bin/bash -eux`

Also known as **Debugging Mode**. The options (`-e`, `-u` and `-x`) are part of the `set` builtin. They have the following meaning:

`-e`

Exit immediately if a pipeline […] returns a non-zero status.

`-u`

Treat unset variables and parameters […] as an error when performing parameter expansion.

`-x`

Print a trace of […] commands and their arguments or associated word lists after they are expanded and before they are executed. Tells the shell to display all commands and their arguments on the terminal while they are executed. This option enables shell tracing mode.

### Other useful options

 `-v` 

(short for verbose) – tells the shell to show all lines in a script while they are read, it activates verbose mode.

`-n` (short for noexec or no ecxecution) – instructs the shell read all the commands, however doesn’t execute them. This options activates syntax checking mode.

For more details and other options:

 [read the manual](https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#The-Set-Builtin).

https://alinuxaday.wordpress.com/2016/12/18/como-habilitar-el-modo-de-depuracion-de-secuencias-de-comandos-de-la-shell-en-linux/
