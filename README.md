# synapse-delurlcache
Delete images and thumbnails created by URL previews in Synapse

**Purpose**

In its current version, when Synapse creates URL previews, the images that are created in media_store/local_content and media_store/local_thumbnails will never be deleted.  Relatively quickly, they can use large amounts of disk space.

This scripts finds all such images that are older than one day (default) and deletes them from the database and the file system.

**Caveats**

* Use at your own risk! The script alters your Synapse database!  Always make a backup copy of the database and maybe the media store directories first.  Don't blame me if everything explodes around you, you have been warned.
* The script assumes you are using PostgreSQL as database backend.  I don't have a homeserver with an Sqlite database I could test with.  PRs welcome.
* Tested with Synapse 0.21.1 (only!).

**Instructions**

Requires the Perl DBI module with Postgres support to be present.  In Debien, that would be libdbi-perl.

Change the variables at the beginning of the script to fit your homeserver.

Start the script with a test:

```./delurlcache.pl 1```

This will delete only one URL cache entry and tell you what it did.

If everything looks ok, you can start it with larger numbers:

```./delurlcache.pl 100 > delurlcache.log```

will delete 100 cache entries.  Note the redirection to a file:  delurlcache.pl intentionally logs every single step it does, so in case something goes wrong, you know where to look if you have to fix things.

If you think it will manage to do everything as it should, you can tell it to delete all images older than the threshold you defined when editing the variables:

```./delurlcache.pl 0 > delurlcache.log```

Good luck!

