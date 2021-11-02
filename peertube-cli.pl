#!/usr/bin/perl

# peertube-cli
# A peertube cli client.
# author: qorg11

use LWP::UserAgent;
use JSON;
use Term::ReadLine;
use Term::ANSIColor;
use strict;
use warnings;

# Objects

my $json = new JSON;
my $ua = new LWP::UserAgent;
my $term = new Term::ReadLine("ptcli");

# Configuration
# TODO: config file or something

our $INSTANCE = "https://vid.qorg11.net";

# Prototypes

sub search_video($);
sub select_video($);
sub get_video_data($);
sub play_video($);

# Main program

if (!$ARGV[0]) {
	print <STDERR>, "No argument given\n";
	my $input = $term->readline("=> ");
	my $response = search_video($input);
	my $json_obj = $json->decode($response);
	my $uuid = &select_video($json_obj);
	my @selected_video_data = get_video_data($uuid);
	play_video(\@selected_video_data);

} else {
	my $response = search_video(join(" ",@ARGV));
	my $json_obj = $json->decode($response);
	my $uuid = &select_video($json_obj);
	my @selected_video_data = get_video_data($uuid);
     play_video(\@selected_video_data);
}

# Functions

sub search_video($) {
	my $search_string = shift;
	my $response = $ua->get("$INSTANCE/api/v1/search/videos?search=$search_string");
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
	for (my $i = 0; $i < $total; $i++) {
		$videos_data[$i] = $json_obj->{data}->[$i];
		print "$i: " . $videos_data[$i]->{name} . "\n";
		
	}
	my $input = $term->readline("=> ");
	return $videos_data[$input]->{uuid};
}

sub get_video_data($) {
	my $uuid = shift;
	my $response = $ua->get("$INSTANCE/api/v1/videos/$uuid");

	if($response->{_rc} == 200) {
		my $json_obj = $json->decode($response->content);
		return ($json_obj->{files}->[0]->{fileUrl},
			   $json_obj->{name},
			   $json_obj->{description},
			   $json_obj->{account}->{name});
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
	print "Video title: $title\n";
	print "Description: $description\n\n";
	print "Video author: $author\n";
	`mpv $url`;
}
