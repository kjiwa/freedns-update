#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use LWP::Simple;
use Net::DNS;
use Socket;

sub get_my_ip_address
{
	my $url = qq(http://freedns.afraid.org/dynamic/check.php);
	my $content = get($url);
	die($!) unless defined($content);

	$content =~ m/Detected IP : (\S+)\n/ or die("Unable to extract IP address");
	my $ip = $1;
	return $ip;
}

sub get_ip_address_by_hostname
{
	my ($domain) = @_;

	my $host = gethostbyname($domain);
	die(sprintf(qq(Unable to determine IP address for %s), $domain)) unless defined($host);
	
	my $ip = inet_ntoa($host);
	return $ip;
}

sub get_ip_address_by_hostname_from_ns
{
	my ($domain, $ns) = @_;
	
	my $res = new Net::DNS::Resolver;
	$res->nameservers($ns);
	
	my @answers = $res->send($domain)->answer;
	foreach my $answer (@answers) {
		my $ip = $answer->{address};
		return $ip if $ip;
	}
	
	die(sprintf(qq(Unable to determine IP address for %s), $domain));
}

sub update_host_ip_address
{
	my ($domain, $key, $ip) = @_;

	my $url = sprintf(qq(http://freedns.afraid.org/dynamic/update.php?%s&address=%s), $key, $ip);
	my $content = get($url);

	unless ($content =~ m/(ERROR: Address \S+ has not changed|Updated \d+ host\(s\) .+ to \S+ in .+ seconds|Updated \S+ to \S+ in .+ seconds)/) {
		die(sprintf(qq(Error updating domain %s to IP %s: %s), $domain, $ip, $content));
	}
}

sub get_args
{
	my %opts;
	my @args = (
		'domain|d=s',
		'key|k=s',
		'ip=s',
		'nameserver|ns=s',
		'force|f',
		'simulate|s',
		'print|p',
		'help|h'
	);

	GetOptions(\%opts, @args);
	if (!exists $opts{domain} || !exists $opts{key}) {
		$opts{help} = 1;
	}

	return %opts;
}

sub usage
{
	my @P = split(/\//, $0);
	my $p = pop(@P);
	
	my $s = <<EOS;
USAGE: %s

Required:
--domain <domain>
--key <key>

Optional:
--ip <ip>
--nameserver <nameserver>
--force
--simulate
--print
--help
EOS

	return sprintf($s, $p);
}

sub fault_handler
{
	my ($e) = @_;
	print(sprintf(qq(%s\n), $e));
	print(sprintf(qq(%s\n), usage));
	exit(-1);
}

sub main
{
	my %args = get_args;

	my $domain = $args{domain};
	my $key = $args{key};
	my $my_ip = $args{ip};
	my $ns = $args{ns};
	my $force = $args{force};
	my $simulate = $args{simulate};
	my $print = $args{print};
	my $help = $args{help};

	if ($help) {
		print(sprintf(qq(%s\n), usage()));
		return 0;
	}

	my $domain_ip = $ns
	                ? get_ip_address_by_hostname_from_ns($domain, $ns)
	                : get_ip_address_by_hostname($domain);

	$my_ip = get_my_ip_address if !defined($my_ip);

	if ($print) {
		print(sprintf(qq(Before:\t%s\n), $domain_ip));
		print(sprintf(qq(After:\t%s\n), $my_ip));
	}

	if (!$simulate
	    and ($force
	         or $domain_ip ne $my_ip)) {
		update_host_ip_address($domain, $key, $my_ip);
	}

	return 0;
}

eval {
	main;
};

fault_handler($@) if $@;
