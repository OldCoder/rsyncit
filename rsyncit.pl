#!/usr/bin/env perl
# rsyncit - Wrapper for "rsync" (a standard backup utility)
# License:  MIT/X
# Revision: 120710

#---------------------------------------------------------------------
#                           important note
#---------------------------------------------------------------------

# This software is provided on an  AS IS basis with ABSOLUTELY NO WAR-
# RANTY.  The  entire risk as to the  quality and  performance of  the
# software is with you.  Should the software prove defective,  you as-
# sume the cost of all necessary  servicing, repair or correction.  In
# no event will any of the developers,  or any other party, be  liable
# to anyone for damages arising out of use of the software, or inabil-
# ity to use the software.

#---------------------------------------------------------------------
#                              overview
#---------------------------------------------------------------------

my $USAGE_TEXT = << 'END_OF_USAGE_TEXT';

Usage: rsyncit         SourceDir TargetDir
or:    rsyncit OPTIONS SourceDir TargetDir

"rsyncit"  is a wrapper for the  standard "rsync" backup program. Sys-
admins may prefer to use "rsync" directly, as its behavior is well-un-
derstood and it provides numerous options.  However,  "rsyncit" may be
useful  in some cases  for  three reasons:  it has a  somewhat simpler
interface than "rsync",  it adds a few sanity checks,  and  it handles
target-directory  paths  consistently  (this  is discussed  at a later
point).

"rsyncit" uses "rsync" to  back-up the specified source directory  and
its subdirectories to a target subdirectory inside the  specified tar-
get directory.

The  target  subdirectory is  transformed into a mirror  of the source
directory.  As a consequence of this, files already stored in the tar-
get subdirectory will be  deleted unless  corresponding files exist in
the source directory.

The  target subdirectory has the same  name as  the  source directory,
minus any higher-level directory components.  For example, the follow-
ing command transforms the directory tree  "/backup/bar" into a mirror
of "/foo/bar":

      rsyncit /foo/bar /backup

Note: This is a possibly significant difference between "rsyncit"  and
"rsync".  "rsync" seems to put files in  different places depending on
whether or not the source path is absolute or relative. "rsyncit" sets
the target subdirectory consistently.

----------------------------------------------------------------------

Backing up "/" (or to "/")  is prohibited. "rsyncit" also detects (and
prohibits) cases where the  source tree is inside the destination tree
or vice versa.

----------------------------------------------------------------------

By  default, the  target subdirectory must already exist. This rule is
intended  to reduce  the chances that files  will be  backed up to the
wrong place. To override the rule and create directories  automatical-
ly, use the option "-d":

      rsyncit -d /foo/bar /backup

The  word switch  "--mkdir" has the  same effect as  the letter switch
"-d":
      rsyncit --mkdir /foo/bar /backup

----------------------------------------------------------------------

By default,  "rsyncit" prints some messages but not a complete list of
files as they're copied.  For verbose operation, which includes a list
of this type, use the option "-v":

      rsyncit -v /foo/bar /backup

The word switch  "--verbose" has the same effect as the  letter switch
"-v":
      rsyncit --verbose /foo/bar /backup

----------------------------------------------------------------------

Single-letter  "rsyncit" option switches may be combined. For example,
"-dv" is equivalent to: -d -v.  Additionally,  option switches  may be
placed at any position in the command line. For example, the following
two commands are equivalent:

      rsyncit -v /foo/bar /backup
      rsyncit    /foo/bar /backup -v

----------------------------------------------------------------------

To perform a dry run (i.e., to show what will be done but not actually
do it), use "-n":

      rsyncit -n /foo/bar /backup

The  "word"  switch "--dry-run" (or "--dryrun") has the same effect as
the "letter" switch "-n":

      rsyncit --dry-run /foo/bar /backup

Note: "-n" and its aliases don't imply "-v".  To produce a verbose ex-
planation of what will be done, add the second switch:

      rsyncit -n -v /foo/bar /backup
or:   rsyncit -nv   /foo/bar /backup

----------------------------------------------------------------------

"rsyncit" supports "rsync"-compatible "--exclude" switches.  For exam-
ple, the following command does a backup that excludes the contents of
# directories named "tmp":

      rsyncit --exclude="*/tmp/*" -v /foo/bar /backup

If excluded objects are present in the backup tree  (for example, from
previous  backup  operation),  "rsyncit"  deletes them.  "rsyncit" and
"rsync" differ in this respect;  "rsync"  only does this if the switch
"--delete-excluded" is specified  ("rsyncit" sets the switch in quest-
ion automatically).

----------------------------------------------------------------------

To  pass  "rsync"-level  option switches to "rsync",  use one  or more
"rsyncit"-level option switches of the form:

      --rs:"--foo --bar=xyzzy"
or:   --rsync:"--foo --bar=xyzzy"

where  "--foo --bar=xyzzy"  are  "rsync"-level switches  separated  by
spaces. The  switches  themselves shouldn't  include  spaces or double
quotes.

Each  "--rs" (or "--rsync")  switch may  specify one or more  "rsync"-
level switches. If two or more "--rsync" switches are used, all of the
specified "rsync"-level switches will be passed.

----------------------------------------------------------------------

If multiple backups are done over time using the same source and  tar-
get directories, "rsyncit" reuses existing backup files when possible.
The algorithm used for this purpose is  good enough for most purposes,
but if files are modified and neither timestamps  nor sizes are chang-
ed, modifications of this type may not be detected and backed up.  The
option "-c" may be used to fix this,  but this option will slow things
down.

The word switch "--checksum" has the  same effect as the letter switch
"-c":
      rsyncit --checksum /foo/bar /backup

----------------------------------------------------------------------

The  letter switch "-f" (or the word switch "--flag") tells  "rsyncit"
to manage a "flag" file related to the current backup:

      rsyncit -f /foo/bar /backup

The "flag" file has the same pathname as the target subdirectory,  but
the string  ".rsynced" is added.  "rsyncit" deletes the file initially
and creates it at the end if the backup appears to be successful.

Note: If an object  with the indicated  flag-file name exists and it's
a symbolic link or  anything but a regular file,  flag-file operations
are skipped.  The "-n" (or "--dry-run") option  also suppresses  flag-
file operations.

----------------------------------------------------------------------

If you'd like to save existing files from the target subdirectory that
are going to be modified or deleted, use  the "letter" switch "-b" (or
the "word" switch "--backup"):

      rsyncit -b /foo/bar /backup

This option moves  the current  versions of files that are going to be
modified or  deleted  to a  second  backup-directory tree.  The second
tree is stored in a  directory named "rsyncbak" that's  located in the
same directory as the target subdirectory.

For example,  "rsyncit -b /foo/bar /backup"  will transform  "/backup/
bar"  into  a mirror of  "/foo/bar" while  saving modified  or deleted
files from "/backup/bar" in "/backup/rsyncbak/bar".

----------------------------------------------------------------------

The  "word"  switch "--go" or "--normal"  (there  is no  corresponding
"letter" switch) is equivalent to:

      -bfv
or:   -b -f -v
or:   --backup --flag --verbose
END_OF_USAGE_TEXT

#---------------------------------------------------------------------
#                        standard module setup
#---------------------------------------------------------------------

require 5.10.1;
use strict;
use Carp;
use warnings;
use Cwd;
                                # Trap warnings
$SIG{__WARN__} = sub { die @_; };

#---------------------------------------------------------------------
#                           basic constants
#---------------------------------------------------------------------

use constant ZERO  => 0;        # Zero
use constant ONE   => 1;        # One
use constant TWO   => 2;        # Two

use constant FALSE => 0;        # Boolean FALSE
use constant TRUE  => 1;        # Boolean TRUE

#---------------------------------------------------------------------
#                         program parameters
#---------------------------------------------------------------------

my $PURPOSE  = 'rsync-based backup tool';
my $REVISION = '120710';
my $USE_LESS = TRUE;            # Flag: Use "less" for usage text

#---------------------------------------------------------------------
#                          global variables
#---------------------------------------------------------------------

my $PROGNAME;                   # Program name (without path)
   $PROGNAME =  $0;
   $PROGNAME =~ s@.*/@@;
   $PROGNAME =~ s@\.pl\z@@i;

#---------------------------------------------------------------------
#                          support routines
#---------------------------------------------------------------------

# "UsageError" prints  usage text and  terminates the program.  If the
# global flag $USE_LESS is true,  output is piped through "less". Oth-
# erwise, it's printed directly.

#---------------------------------------------------------------------

sub UsageError
{
    $USAGE_TEXT =~ s@^\s+@@s;   # Remove leading white space
    $USAGE_TEXT =  << "END";    # "END" must be double-quoted here
$PROGNAME $REVISION - $PURPOSE

$USAGE_TEXT
END
                                # Canonicalize trailing white space
    $USAGE_TEXT =~ s@\s*\z@\n@s;
                                # Display text using "less" ?
    if ($USE_LESS && (-t STDOUT) && open (OFD, "|/usr/bin/less"))
    {                           # Yes
                                # "END" must be double-quoted here
        $USAGE_TEXT = << "END";
To exit this "help" text, press "q" or "Q".  To scroll up or down, use
PGUP, PGDN, or the arrow keys.

$USAGE_TEXT
END
        print OFD $USAGE_TEXT;
        close OFD;
    }
    else
    {                           # No  - Just print it
        print "\n", $USAGE_TEXT, "\n";
    }

    exit ONE;                   # Exit the program
}

#---------------------------------------------------------------------
#                            main routine
#---------------------------------------------------------------------

sub Main
{
    my $FlagBackup   = FALSE;   # Flag: -b (or --backup   ) option
    my $FlagChecksum = FALSE;   # Flag: -c (or --checksum ) option
    my $FlagFlag     = FALSE;   # Flag: -f (or --flag     ) option
    my $FlagMkdir    = FALSE;   # Flag: -d (or --mkdir    ) option
    my $FlagDryRun   = FALSE;   # Flag: -n (or --dry-run  ) option
    my $FlagVerbose  = FALSE;   # Flag: -v (or --verbose  ) option

    my $OptRsync     = "";      # "rsync" switches (or empty)
    my $n;                      # Scratch (integer)
    my $str;                    # Scratch (string )

#---------------------------------------------------------------------
# Initial setup.

                                # Note: STDERR must be set first here
    select STDERR; $| = ONE;    # Force STDERR flush on write
    select STDOUT; $| = ONE;    # Force STDOUT flush on write
    my $origcwd = getcwd();     # Initial working directory

#---------------------------------------------------------------------
# Process the command line.

    my @ARGX = ();              # Rebuilt argument list

    for my $arg (@ARGV)         # Process all  arguments
    {                           # Process next argument

                                # Handle simple optionswitches
        if ($arg =~ m@^(-b|-+backup)\z@i)
            { $FlagBackup   = TRUE; next; }
        if ($arg =~ m@^(-c|-+checksum)\z@i)
            { $FlagChecksum = TRUE; next; }
        if ($arg =~ m@^(-d|-+mkdir)\z@i)
            { $FlagMkdir    = TRUE; next; }
        if ($arg =~ m@^(-f|-+flag)\z@i)
            { $FlagFlag     = TRUE; next; }
        if ($arg =~ m@^(-n|-+dry-*run)\z@i)
            { $FlagDryRun   = TRUE; next; }
        if ($arg =~ m@^(-v|-+verbose)\z@i)
            { $FlagVerbose  = TRUE; next; }

        if ($arg =~ m@^(-+go|-+normal)\z@i)
            { $FlagBackup = $FlagFlag = $FlagVerbose = TRUE; next; }

                                # Handle "--exclude="
        if ($arg =~ m@^-+exclude=(.+)\z@i)
        {
            $str = $1;
            $OptRsync =  "" unless defined $OptRsync;
            $OptRsync .= " --delete-excluded"
                unless $OptRsync =~ m@--delete-excluded\b@;
            $OptRsync .= " --exclude=$str";
            $OptRsync =~ s@^\s+@@;
            $OptRsync =~ s@\s+\z@@;
            $OptRsync =~ s@\s+@ @s;
            next;
        }
                                # Handle "--rs=" and "--rsync="
        if ($arg =~ m@^--rs(ync|)=(.+)\z@i)
        {
            $str = $2;
            $OptRsync =  "" unless defined $OptRsync;
            $OptRsync .= " $str";
            $OptRsync =~ s@^\s+@@;
            $OptRsync =~ s@\s+\z@@;
            $OptRsync =~ s@\s+@ @s;
            next;
        }
                                # Handle letter-switch combinations
        if ($arg =~ s@^-@@)
        {
            my $argh = $arg;
            $FlagBackup   = TRUE if $arg =~ s@b@@g;
            $FlagChecksum = TRUE if $arg =~ s@c@@g;
            $FlagMkdir    = TRUE if $arg =~ s@d@@g;
            $FlagFlag     = TRUE if $arg =~ s@f@@g;
            $FlagDryRun   = TRUE if $arg =~ s@n@@g;
            $FlagVerbose  = TRUE if $arg =~ s@v@@g;
            next unless length $arg;
            die "Invalid argument: -$argh\n";
        }

        push (@ARGX, $arg);     # Use  remaining arguments  to build a
                                # new list
    }
                                # There  should be  exactly two  argu-
                                # ments at this point
    &UsageError() unless scalar (@ARGX) == TWO;

    my ($src, $dst) = @ARGX;    # Source and target directories

#---------------------------------------------------------------------
# Basic directory checks.

# These checks are safety measures.

    die "Error: Source directory doesn't exist: $src\n"
        unless -e $src;
    die "Error: Source isn't a directory: $src\n"
        unless -d $src;
    die "Error: Destination directory doesn't exist: $dst\n"
        unless -e $dst;
    die "Error: Destination isn't a directory: $dst\n"
        unless -d $dst;

    die "Error: Not intended for backing up /\n"      if $src eq '/';
    die "Error: Not intended for backing up into /\n" if $dst eq '/';

#---------------------------------------------------------------------
# Get canonical versions of directory paths.

# This code checks the source and target directories and obtains  can-
# onical paths for them at the same time.  For example, relative paths
# are converted to absolute.

                                # Source directory
    chdir ($dst)
        || die "Error: Can't enter directory: $!\n$dst\n";
    $dst = getcwd();
    chdir ($origcwd)
        || die "Error: Can't enter directory: $!\n$origcwd\n";

                                # Target directory
    chdir ($src)
        || die "Error: Can't enter directory: $!\n$src\n";
    $src = getcwd();
    chdir ($origcwd)
        || die "Error: Can't enter directory: $!\n$origcwd\n";

#---------------------------------------------------------------------
# Determine target subdirectory.

# "rsyncit"  copies files  into a subdirectory of the target directory
# that  has  the  same name  as the  last part of the source-directory
# path.

# For example, if the source directory  is  "/foo/bar/sauce"  and  the
# target directory is "/bacon/apple", the source directory is mirrored
# in the subdirectory "/bacon/apple/sauce".

# This code sets $sub to an absolute path for the subdirectory.

    $str =  $src;
    $str =~ s@^.*/@@;
    my $base = $str;
    my $sub  = "$dst/$base";

#---------------------------------------------------------------------
# Additional directory checks.

# This code implements more safety measures.

    die "Error: Can't back up from or into an rsyncbak tree\n"
        if ($base =~ m@/rsyncbak(|\z)@) ||
           ($sub  =~ m@/rsyncbak(|\z)@);

    $n = length ($sub);
    ($str) = $sub =~ m@^(.{$n})(/|\z)@;
    die "Error: That would overwrite the source tree\n"
        if defined ($str) && ($str eq $src);

    $n = length ($src);
    ($str) = $dst =~ m@^(.{$n})(/|\z)@;
    die "Error: Destination can't be inside source\n"
        if defined ($str) && ($str eq $src);

    $n = length ($dst);
    ($str) = $src =~ m@^(.{$n})(/|\z)@;
    die "Error: Source can't be inside destination\n"
        if defined ($str) && ($str eq $dst);

    die "Error: R,X privileges are needed for directory: $src\n"
        unless (-r $src) && (-x $src);
    die "Error: R,W,X privileges are needed for directory: $dst\n"
        unless (-r $dst) && (-w $dst) && (-x $dst);

#---------------------------------------------------------------------
# Handle the "-d" option.

    if (!$FlagMkdir && (!-d $sub))
    {
        print << "END";
The source directory "$src" will be backed up into:
$sub

The latter directory doesn't exist yet and as a safety measure it
won't be created automatically.  To proceed, create the directory
and try again. Or use the option "-d" to create directories auto-
matically.
END
        exit ONE;
    }

#---------------------------------------------------------------------
# More directory checks.

# This code is safety measures again. It's better to be safe than sor-
# ry.

    if (-e $sub)
    {
        die "Error: Not a directory: $sub\n"
            unless -d $sub;
        die "Error: R,W,X privileges are needed for directory: $sub\n"
            unless (-r $sub) && (-w $sub) && (-x $sub);
    }

#---------------------------------------------------------------------
# Set up secondary backup tree.

    my $bax;                    # Pathname for secondary tree

    if ($FlagBackup)            # Need to do this?
    {                           # Yes
                                # Build pathname
        $str =  $sub;
        $str =~ s@/[^/]+\z@/rsyncbak@;
        $bax =  $str;
        die "Internal error #0001\n" unless $bax =~ m@/rsyncbak\z@;

                                # Create directory if appropriate
        mkdir ($bax, 0755) unless -e $bax;

                                # Directory checks
        die "Error: Secondary tree isn't a directory: $bax\n"
            unless -d $bax;
        die "Error: R,W,X privileges are needed for directory: $bax\n"
            unless (-r $bax) && (-w $bax) && (-x $bax);
    }

#---------------------------------------------------------------------
# Build appropriate "rsync" command.

    @ARGX = ();
    push @ARGX, 'rsync', '-a', '--delete';

    if ($FlagBackup)
    {
        push (@ARGX, "--backup-dir=$bax");
        push (@ARGX, '-b');
    }

    if ($FlagChecksum ) { push @ARGX, '-c'; }
    if ($FlagDryRun   ) { push @ARGX, '-n'; }
    if ($FlagVerbose  ) { push @ARGX, '-v'; }

    if (length ($OptRsync))
    {
        push @ARGX, split (/\s+/, $OptRsync);
    }

    push @ARGX, $src, $dst;

#---------------------------------------------------------------------
# Set up "flag" file.

                                # Pathname for "flag" file
    my $StatusFile = "$sub.rsynced";
                                # Checks related to "flag" file
    $FlagFlag = FALSE if -l $StatusFile;
    $FlagFlag = FALSE if (-e $StatusFile) && (!-f $StatusFile);

                                # Delete "flag" file if appropriate
    unlink $StatusFile if $FlagFlag && !$FlagDryRun;

#---------------------------------------------------------------------
# Perform actual operations.

                                # Print argument list
    print join (' ', @ARGX) . "\n";
    my $status = system @ARGX;  # Run "rsync"
                                # Extract error flag
       $status = int ($status / 256);

#---------------------------------------------------------------------
# Wrap it up.

    if ($status)                # Error?
    {                           # Yes
                                # Print a status message
        print "Error exit\n" if $FlagVerbose;

                                # Delete "flag" file if appropriate
                                # Note: Just  a  safety  measure  (the
                                # file should already be  gone at this
                                # point)

        unlink $StatusFile if $FlagFlag && !$FlagDryRun;
        exit ONE;               # Error exit
    }
    else
    {                           # No
                                # Print a status message
        print "Apparently successful\n" if $FlagVerbose;

        if (!$FlagDryRun)       # Create "flag" file
            { open (OFD, ">$StatusFile") && close (OFD); }
    }
}

#---------------------------------------------------------------------
#                            main program
#---------------------------------------------------------------------

&Main();                        # Call the main routine
exit ZERO;                      # Normal exit
