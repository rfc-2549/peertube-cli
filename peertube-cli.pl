#!/usr/bin/perl

# peertube-cli
# A peertube cli client.
# author: qorg11

use LWP::UserAgent;
use JSON;
use Term::ReadLine;
use Term::ANSIColor;
use Getopt::Long;
use Time::Seconds;
use warnings;
use strict;

our %config;

# Objects

my $json = new JSON;
my $ua = new LWP::UserAgent;
$ua->agent("curl");
my $term = new Term::ReadLine("ptcli");
my $time = new Time::Seconds;

# Configuration
my $conf_path = $ENV{PTCLIRC} || "$ENV{HOME}/.ptclirc";

do $conf_path or die "Could not load configuration: $!";

# Prototypes

sub search_video($$);
sub select_video($);
sub get_video_data($);
sub play_video($);
our $counter = 0;

# Process arguments

GetOptions(
		 "instance=s"   => \$config{instance},
		 "resolution=i" => \$config{default_resolution},
		 "player=s"     => \$config{player}
		);
# Main program

if (!$ARGV[0]) {
	print "No argument given\n";
	my $input = $term->readline("=> ");

	my $response;
	my $uuid = -1;
	my @selected_video_data;
	while($uuid == -1) {
		$response = search_video($input, $counter);
		my $json_obj = $json->decode($response);
		$uuid = &select_video($json_obj);
		@selected_video_data = get_video_data($uuid);
	}
	play_video(\@selected_video_data);

} else {
	
	my $response;
	my $uuid = -1;
	my @selected_video_data;
	while($uuid == -1) {
		$response = search_video(join("",@ARGV), $counter);
		if($response eq "-1") {
			print colored['bold red'], "ERROR\n";
		}
		my $json_obj = $json->decode($response);
		$uuid = &select_video($json_obj);
		@selected_video_data = get_video_data($uuid);
	}
	play_video(\@selected_video_data);

}

# Functions

sub search_video($$) {
	my ($search_string, $counter) = @_;
	my $response = $ua->get("$config{instance}/api/v1/search/videos?search=$search_string&count=25&start=$counter");
	if ($response->{_rc} == 200) {
		return $response->content;
	} else {
		return -1;
	}
}

sub select_video($) {
	my $json_obj = shift;
	my @videos_data;
	my $total = $json_obj->{total};
	$total = 25 if $total > 25;
	print colored['bold'], "Connected to $config{instance}\n";
	print "Select the video you want to play (:h for help)\n";
	for (my $i = 0; $i < $total; $i++) {
		$videos_data[$i] = $json_obj->{data}->[$i];
		printf("%5i: %-104s %-1s\n",
			  $i,
			  colored(['bold'], $videos_data[$i]->{name}),
			  "--- " . colored(['green'], $videos_data[$i]->{account}->{name}),
			 );
	}
	my $input = $term->readline("=> ");
	if ($input eq "n" || $input eq "N") {
		$counter += 25;
		return -1;
	}
	elsif ($input eq "p" || $input eq "P") {
		$counter -= 25;
		return -1;
	} elsif($input eq ":h") {
		&help_prompt();
		return -1;
	}

	return $videos_data[$input]->{uuid};
}

sub get_video_data($) {
	my $uuid = shift;
	my $response = $ua->get("$config{instance}/api/v1/videos/$uuid");

	if ($response->{_rc} == 200) {
		my $json_obj = $json->decode($response->content);
		return ($json_obj->{files}->[$config{default_resolution}]->{fileUrl},
			   $json_obj->{name},
			   $json_obj->{description},
			   $json_obj->{account}->{name},
			   $json_obj->{files}->[$config{default_resolution}]->{resolution}->{id});
	} else {
		return "error\n";
	}
}

sub play_video($) {
	my $ref = $_[0];
	my ($url, $title, $description, $author, $resolution) = @$ref;
	print "Video title: $title\n";
	print "Description: $description\n\n";
	print "Video author: $author\n";
	print "Resolution: $resolution\n";
	
	`$config{player} $url`;
}

sub help_prompt() {
	print "n: next page\n";
	print "p: previous page\n";
	print ":h show this\n";
	print "Press enter to continue\n";
	<STDIN>;
}
