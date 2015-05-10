# FreeDNS Updater

Users of [FreeDNS](https://freedns.afraid.org/) can use this script to update
DNS records whenever an IP changes. It acts by querying the A record for your
domain and for your public IP. If there is a mismatch between them, an update is
invoked.

The script is written in Perl and accepts the following options:

* Required:
  * --domain <domain>
  * --key <key>
* Optional:
  * --ip <ip>
  * --nameserver <nameserver>
  * --force

The script will query FreeDNS to find out your public IP if you do not specify
an IP with --ip.

You can specify which DNS server you want the script to query when it is
checking your domain records. This is useful if you have an internal DNS server
that maps your domain to a private IP.

By default, the script will not invoke an update if the domain's A record is the
same as your IP. You can force an update with the --force option.
