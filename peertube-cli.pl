#!/usr/bin/perl

# peertube-cli
# A peertube cli client.
# author: qorg11

use LWP::UserAgent;
use JSON;
use Term::ReadLine;
use Term::ANSIColor;
use Getopt::Long;

# Objects

my $json = new JSON;
my $ua = new LWP::UserAgent;
my $term = new Term::ReadLine("ptcli");

# Configuration
my $conf_path = $ENV{PTCLIRC} || "$ENV{HOME}/.ptclirc";

do $conf_path;

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
		print color('red');
		return sprintf("ERROR: server returned status code $response->{_rc}\n");
	}
}

sub select_video($) {
	my $json_obj = shift;
	my @videos_data;

	my $total = $json_obj->{total};
	$total = 25 if $total > 25;
	for (my $i = 0; $i < $total; $i++) {
		$videos_data[$i] = $json_obj->{data}->[$i];
		print "$i: " . $videos_data[$i]->{name} . "\n";
		
	}
	my $input = $term->readline("=> ");
	if ($input eq "n" || $input eq "N") {
		$counter += 25;
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
	my $url = $ref->[0];
	my $title = $ref->[1];
	my $description = $ref->[2];
	my $author = $ref->[3];
	my $resolution = $ref->[4];
	print "Video title: $title\n";
	print "Description: $description\n\n";
	print "Video author: $author\n";
	print "Resolution: $resolution\n";
	
	`$config{player} $url`;
}
