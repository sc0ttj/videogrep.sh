# Videogrep.sh

Search videos for matching words or phrases, and generate a cut-down version
in the `~/videogrep_output/` directory, containing only the matching dialogue.

For example, keep only the bits of a video where people say "banana".

## Requirements

### Dependencies

- `bash` - it's a bash script
- `egrep` - for finding matches in the subtitles
- `ffprobe` for getting video information like dimensions, aspect ratio (in FFMPEG package)
- `bc` - for calculating accurate video frame rates
- `mencoder` - for creating the generated video
- `mplayer` - for playing the generated video

### Video requirements

- Put the videos you want to search, _and their subtitle files_, in a directory together.
- The source videos _must_ have accompanying subtitles files, in either `.srt` or `.sub` format!
- The subtitle file names must also match the videos to which they refer.
- Here's a valid example (`videogrep` will find the subtitles OK):

```
./some_vids/my-cool-video-1080p.mp4
./some_vids/my-cool-video-1080p.srt
```

NOTE: Many YouTube videos have subtitles. You can download YouTube videos _and their subtitles_ using various websites.

## Installation

Copy `videogrep.sh` to a folder in your `$PATH`.

## Usage:

You must give:

- the input video (must have a matching subtitle file)
- the search term (can be an `egrep` regex like `one|two|every.*|a whole phrase`

```shell
videogrep.sh <video-file> <search-term> [padding-start] [padding-end]
```

Example:

```shell
videogrep.sh 'my_videos/owen-jones-meets-jeremy-corbyn-again.mp4' 'parliamentary' 50 85
```

Note: `padding-start` and `padding-end` are in milliseconds.

Produces this output:

```console
Video file:     owen-jones-meets-jeremy-corbyn-again.mp4
Subtitle file:  owen-jones-meets-jeremy-corbyn-again.sub
Search term(s): parliamentary

Speech found:

{8748}{8780}the mind by the parliamentary Labour
{10080}{10134}parliamentary by-elections with
{10619}{10676}throughout the parliamentary party and
{12330}{12381}parliamentary speeches on the budget for
{21950}{22002}firefighting within the parliamentary
{64168}{64202}parliamentary so things will come back


------------------------------------
Creating: /root/videogrep_output/parliamentary__owen-jones-meets-jeremy-corbyn-again.avi
------------------------------------
```

## History

The `videogrep.sh` script in this repo is based on a shell script from http://activearchives.org/wiki/Videogrep

Improvements I made to the original script:

- auto detect correct frame rate, dimensions and aspect ratio
- support regex searches better
- added ability to add padding around matching dialogue segments (in milliseconds)
- actually build the cut-down video as a new file, don't just play it

I used this random shell script as inspiration because [antiboredom/videogrep](https://github.com/antiboredom/videogrep) didn't work for me.
(The ffmpeg supplied by `moviepy` segfaults, and switching to my local ffmpeg removed all errors, but still didn't produce any output video.)
