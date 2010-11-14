# Ssync

__Ssync__, an optimised S3 sync tool using the power of Unix!

## Requirements

- Ruby 1.8 or 1.9
- RubyGems
- 'aws-s3' rubygem
- `find`, `xargs` and `openssl`

## Installation

    gem install ssync

## Configuration

To configure, run `ssync setup` and follow the prompts, you'll
need your AWS keys, the local file path you want to back up, the bucket name
to back up to, and any extra options to pass into find (i.e. for ignoring
filepaths etc). It'll write the config to `~/.ssync/my-s3-bucket.yml`.

## Synchronisation

To sync, run `ssync sync` and away it goes.

In the case of a corrupted/incomplete synchronisation, run `ssync sync -f`
or `ssync sync --force` to force a checksum comparison.

## Sync to Multiple Buckets

If you would like to sync to more than one S3 buckets, you may do so by:

    ssync setup my-s3-bucket
    ssync sync my-s3-bucket

    ssync setup another-s3-bucket
    ssync sync another-s3-bucket

Running `ssync setup` and `ssync sync` without any bucket names defaults to using the last bucket you used.

## Why?

This library was written because we needed to be able to back up loads of
data without having to worry about if we had enough disk space on the remote.
That's where S3 is nice.

We tried [s3sync](http://www.s3sync.net/) but it blew our server load (we do in excess of
500,000 requests a day (page views, not including hits for images and what not,
and the server needs to stay responsive). The secret sauce is using the Unix
`find`, `xargs` and `openssl` commands to generate md5 checksums for comparison.
Seems to work quite well for us (we have almost 90,000 files to compare).

Initially the plan was to use `find` with `-ctime` but S3 isn't particularly nice about
returning a full list of objects in a bucket (default is 1000, and I want all
90,000, and it ignores me when I ask for 1,000,000 objects). Manifest generation
on a server under load is fast enough and low enough on resources so we're sticking
with that in the interim.

FYI when you run sync, the output will look something like this:

    [Thu Apr 01 11:50:25 +1100 2010] Starting, performing pre-sync checks ...
    [Thu Apr 01 11:50:26 +1100 2010] Generating local manifest ...
    [Thu Apr 01 11:50:26 +1100 2010] Fetching remote manifest ...
    [Thu Apr 01 11:50:27 +1100 2010] Performing checksum comparison ...
    [Thu Apr 01 11:50:27 +1100 2010] Pushing /tmp/backups/deep/four ...
    [Thu Apr 01 11:50:28 +1100 2010] Pushing /tmp/backups/three ...
    [Thu Apr 01 11:50:29 +1100 2010] Pushing /tmp/backups/two ...
    [Thu Apr 01 11:50:30 +1100 2010] Pushing local manifest up to remote ...
    [Thu Apr 01 11:50:31 +1100 2010] Sync complete!

You could pipe sync into a log file, which might be nice.

Have fun!

## Authors

- [Ryan Allen](https://github.com/ryan-allen)
- [Fred Wu](https://github.com/fredwu)

This project is brought to you by [Envato](http://envato.com/) Pty Ltd.
