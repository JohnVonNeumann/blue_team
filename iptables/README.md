# IPTABLES

Much of what will be in here will be based off the No Starch Press book Linux Firewalls. I will be adapting stuff as I go to suit other setups and whatnot.

The important thing to remember with `iptables` is that the rules are NOT persistent across reboots, which is semi-less-annoying on a "real" server but for your localhost really annoying. In order to get around this, you'll have to use a combination of `iptables-save` and `iptables-restore` along with `/etc/rc.local` which will perform the actions upon reboots. Naturally on a server you'd want to do the same thing, but servers tend to not be reboot as often, and if you're doing server ops properly, you'll just rebuild and reapply the rules (along with updates).
