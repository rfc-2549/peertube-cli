# peertube-cli

A CLI client for peertube

## Why?

JavaScript sucks and i'm not willing to enable it.

## How?

`./peertube-cli <search query>`

If search query is not given, `peertube-cli` will prompt an
interactive search.

## TODO

* Config file [X]
* let user select video player (through config file) [X]
* getopt for instance, and maybe video player :^) [X]
* Directly pass an URL to play the video (Get UUID from url and call `get_video_data()`

## Options

* `--instance` instance to use. `$config{instance}` in .ptclirc.
* `--resolution` resolution to use. `0` should be the highest while `n` is the lowlest `$config{resolution}` in .ptclirc.
* `--player` player to use (e.g. mpv, vlc...). `$config{player}` in .ptclirc.

## Tricks

**Download a video:** set `"wget"` as as player.

## Bugs

Sure.

