#!/usr/bin/perl
use strict;

# hostname for the database connection
my $dbhost = 'localhost';

# database name
my $dbname = 'synapse';

# database user
my $dbuser = 'user';

# database password
my $dbpwd = 'password';

# path to Synapse's media store directory
# if unsure, look up the variable media_store_path in homeserver.yaml
my $mediastore = '/path/to/synapse/media_store';

# everything that is older than current time - $delage seconds will be deleted
# default: 86400 == one day
my $delage = 86400;

my ($db, $quc, $qt, $ruc, $i, $res, $media_id, $name);

my $count = $ARGV[0];

unless ($count =~ /^\d+$/)
	{
	usage();
	}

if ($count == 0)
	{
	$count = 1_000_000_000_000;
	}

use DBI;

$db = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost", $dbuser, $dbpwd, {'RaiseError' => 1});

# find all cached images that are older than a day
$quc = $db->prepare('select * from local_media_repository_url_cache where download_ts < ' . (time() - $delage) * 1000);
$qt = $db->prepare('select * from local_media_repository_thumbnails where media_id = ?');
$quc->execute();

$i = 0;

while ($ruc = $quc->fetchrow_hashref() and $i < $count)
	{
	$media_id = $ruc->{media_id};
	print "Found $media_id from " . localtime($ruc->{download_ts} / 1000) . "\n";
	$qt->execute($media_id);
	my $x = $qt->fetchrow_hashref();
	if ($x)
		{
		print "Removing thumbnail entries from database:\n";
		$res = $db->do("delete from local_media_repository_thumbnails where media_id = '$media_id'");
		if ($res == 0)
			{
			die("Database statement failed: " . $db->errstr);
			}
		else
			{
			print "$res rows removed.\n";
			}
		print "Deleting thumbnail files:\n";
		$media_id =~ /(..)(..)(.*)/;
		$name = "$mediastore/local_thumbnails/$1/$2/$3";
		foreach (<$name/*>)
			{
			print "$_\n";
			unlink($_) or die("Couldn't remove file $_: $!\n");
			}
		rmdir($name);
		}
	else
		{
		print "No thumbnails.\n";
		}
	print "Removing media store entry from database:\n";
	$res = $db->do("delete from local_media_repository where media_id = '$media_id'");
	if ($res == 0)
		{
		print "Not present in media store. Assuming we already deleted this entry.\n";
		print "-----------------\n";
		next;
		}
	else
		{
		print "$res row removed.\n";
		}
	print "Deleting image file:\n";
	$media_id =~ /(..)(..)(.*)/;
	$name = "$mediastore/local_content/$1/$2/$3";
	print "$name\n";
	unlink($name) or die("Couldn't remove file $_: $!\n");
	print "Removing URL cache entry from database:\n";
	$res = $db->do("delete from local_media_repository_url_cache where media_id = '$media_id'");
	if ($res == 0)
		{
		die("Database statement failed: " . $db->errstr);
		}
	else
		{
		print "$res row(s) removed.\n";
		}
	$i++;
	print "-----------------\n";
	}

# don't show error message if we haven't used all available rows
if ($i == $count)
	{
	$quc->finish();
	}
$db->disconnect();

print "\nRemoved $i URL preview images.\n";

sub usage
	{
	print <<EOM;
Usage:
delurlcache.pl <number>
where <number> is maximum number of records you want to delete.
Use 0 for no limit.
delurlcache.pl will output lots of log information on STDOUT, so it's a
good idea to redirect STDOUT to some file.
If an error occurs, it will stop immediately.
EOM
	exit();
	}
