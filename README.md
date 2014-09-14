Tagfiles manager
================

This is a [tagfiles](http://www.slackbook.org/html/package-management-making-tags-and-tagfiles.html) manager for Slackware Linux. You can use it to make a more customized installation of Slackware Linux.

Examples
--------

For example:

    $ bash ./tagfiles_manager.sh -C all -q -s "essential dev" -g

The command above generated tagfiles as follows:
* First disable all packages
* **-q** enables all "recommended" packages (this comes from Slackware itself)
* **-s** option enables the essential & dev categories (internal categories for tagfiles manager)
* **-g** greps for the package counts

The result is a very minimal installation with only 135 packages, but it still has fully functional dev environment to compile stuff.
