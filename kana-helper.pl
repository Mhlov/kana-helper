#!/usr/bin/perl
#===============================================================================
#  DESCRIPTION: Helper for practicing in writing kana.
#
#         TODO: 
#
#       AUTHOR: ΜΗΛΟΝ
#      CREATED: 24-05-2021 16:46
#===============================================================================
use Modern::Perl '2020';
use utf8;
use strict;
use autodie;
use warnings;
use English;

# Unicode
use warnings  qw/FATAL utf8/;
use open      qw/:std :utf8/;
use charnames qw/:full/;
use feature   qw/unicode_strings/;

use Getopt::Long qw/:config posix_default gnu_getopt no_ignore_case/;

use List::Util qw/shuffle/;           # https://perldoc.perl.org/List/Util.html

# DEBUGGING
use Carp;                       # 'carp' for warn, 'croak' for die
                                # https://perldoc.perl.org/Carp.html

use Data::Printer;              # Usage: p @array;
# or use DDP;                   # https://metacpan.org/pod/Data::Printer

use LWP::UserAgent;


our $VERSION = '0.02';

my %option = (
    show_help   => 0,
    ordered     => 0,
    silent      => 0,
    local       => 0,
    download    => 0,
);

my @romaji = qw/
    a i u e o
    ka ki ku ke ko          kya kyu kyo
    sa shi su se so         sha shu sho
    ta chi tsu te to        cha chu cho
    na ni nu ne no          nya nyu nyo
    ha hi fu he ho          hya hyu hyo
    ma mi mu me mo          mya myu myo
    ya    yu    yo
    ra ri ru re ro          rya ryu ryo
    wa          wo
    n
    ga gi gu ge go          gya gyu gyo
    za ji zu ze zo          ja ju jo
    da ji(d) zu(d) de do    ja(d) ju(d) jo(d)
    ba bi bu be bo          bya byu byo
    pa pi pu pe po          pya pyu pyo
    vu
/;

my @hiragana = qw/
    あ い う え お
    か き く け こ      きゃ きゅ きょ
    さ し す せ そ      しゃ しゅ しょ
    た ち つ て と      ちゃ ちゅ ちょ
    な に ぬ ね の      にゃ にゅ にょ
    は ひ ふ へ ほ      ひゃ ひゅ ひょ
    ま み む え も      みゃ みゅ みょ
    や    ゆ    よ
    ら り る れ ろ      りゃ りゅ りょ
    わ          を
    ん
    が ぎ ぐ げ ご      ぎゃ ぎゅ ぎょ
    ざ じ ず ぜ ぞ      じゃ じゅ じょ
    だ ぢ づ で ど      ぢゃ ぢゅ ぢょ
    ば び ぶ べ ぼ      びゃ びゅ びょ
    ぱ ぴ ぷ ぺ ぽ      ぴゃ ぴゅ ぴょ
/;

my @katakana = qw/
    ア イ ウ エ オ
    カ キ ク ケ コ      キャ キュ キョ
    サ シ ス セ ソ      シャ シュ ショ
    タ チ ツ テ ト      チャ チュ チョ
    ナ ニ ヌ ネ ノ      ニャ ニュ ニョ
    ハ ヒ フ ヘ ホ      ヒャ ヒュ ヒョ
    マ ミ ム メ モ      ミャ ミュ ミョ
    ヤ    ユ    ヨ
    ラ リ ル レ ロ      リャ リュ リョ
    ワ          ヲ
    ン
    ガ ギ グ ゲ ゴ      ギャ ギュ ギョ
    ザ ジ ズ ゼ ゾ      ジャ ジュ ジョ
    ダ ヂ ヅ デ ド      ヂャ ヂュ ヂョ
    バ ビ ブ ベ ボ      ビャ ビュ ビョ
    パ ピ プ ペ ポ      ピャ ピュ ピョ
    ヴ
/;

# https://www.kanji.org/japanese/kanaroma/kanaroma.htm
my $sounds_prexif = "https://www.kanji.org/japanese/kanaroma/sounds/";
my @sounds = qw/
    a i u e o
    ka ki ku ke ko      kya kyu kyo
    sa shi su se so     sha shu sho
    ta chi tsu te to    cha chu cho
    na ni nu ne no      nya nyu nyo
    ha hi fu he ho      hya hyu hyo
    ma mi mu me mo      mya myu myo
    ya    yu    yo
    ra ri ru re ro      rya ryu ryo
    wa          wo
    n
    ga gi gu ge go      gya gyu gyo
    za ji zu ze zo      ja ju jo
    da di du de do      dya dyu dyo
    ba bi bu be bo      bya byu byo
    pa pi pu pe po      pya pyu pyo
    vu
/;

my $sounds_dir = "$ENV{HOME}/.local/share/kana-helper/sounds";

sub get_sound_file_name { return "$sounds_dir/" . shift . '.wav' }
sub get_sound_file_url  { return $sounds_prexif . shift . '.wav' }


sub download_all_sounds {
    state $ua = LWP::UserAgent->new();

    if (-e $sounds_dir) {
        die "File '$sounds_dir' is not a directory!\n" unless -d $sounds_dir;
        die "Directory '$sounds_dir' is not writable!\n" unless -w $sounds_dir;
    } else {
        require File::Path;
        File::Path::make_path($sounds_dir)
            or die "Can't create dir '$sounds_dir' $!";
    }

    say "Downloading sounds, please wait...";

    foreach my $sound (@sounds) {
        my $url = get_sound_file_url($sound);
        my $response = $ua->head($url);

        my $file = get_sound_file_name($sound);
        if ($response->is_success) {
            if (    -e $file
                and -s $file == $response->header('Content-Length') )
            {
                #say "File already exists. Skiped.";
                next;
            }
            else {
                say "Downloading sounds, please wait...";
                system wget => $url, '-O', get_sound_file_name($sound);
            }
        }
    }
    return 1;
}


sub options {
    GetOptions(
        "help|h"        => \$option{show_help},
        "ordered|o"     => \$option{ordered},
        "silent|s"      => \$option{silent},
        "download|d"    => \$option{download},
    ) or die ">_<\n";

    if (not $option{silent}) {
        if (-e $sounds_dir) {
            foreach my $sound (@sounds) {
                if (-e get_sound_file_name ($sound)) {
                    $option{local} = 1;
                    last;
                }
            }
        }

        #if (not $option{local}) {
        #    $option{local} = 1 if download_all_sounds();
        #}
    }

    if ($option{download}) {
        $option{local} = 1 if download_all_sounds();
    }
}


sub play_sound {
    my $i = shift;
    my $mpv = sub {
        `mpv $_[0] 2>&1`;
    };

    if ($option{local}) {
        my $file = get_sound_file_name ($sounds[$i]);
        if (-e $file) {
            $mpv->($file);
            return 1;
        }
        else { return 0 }
    }
    else {
        state $ua = LWP::UserAgent->new();
        my $url = get_sound_file_url ($sounds[$i]);
        if ($ua->head($url)->is_success) {
            $mpv->($url);
            return 1;
        }
        else { return 0 }
    }
}


sub help {
    require Pod::Usage;
    Pod::Usage::pod2usage(-verbose => 99);
}

sub main {
    options();
    help() if $option{show_help};

    say "Press Enter to continue;";
    say "Ctrl-C to exit.";

    foreach my $i ($option{ordered} ? 0..$#romaji : shuffle 0..$#romaji) {
        state $n = 0;
        my $status = sprintf "-[%i/%i]%s",
                             ++$n,
                             scalar @romaji,
                             "-"x(4-length $n);
        say $status;
        print $romaji[$i];
        play_sound($i) unless $option{silent};
        readline;
        print "$hiragana[$i] " if defined $hiragana[$i];
        say "$katakana[$i]";
    }
    0;
}

exit main(@ARGV);


__END__

################################################################################

=head1 NAME

kana-helper.pl - Helper for practicing in writing kana.

=head1 SYNOPSIS

B<kana-helper.pl> [options]

=head1 OPTIONS

=over 16

=item B<< -o  --ordered >>

Don't shuffle kana.

=item B<< -s  --silent >>

Don't play sounds.

=item B<< -d  --download >>

Download sounds to local storage.

=item B<< -h  --help >>

Show this help.

=back

=cut

################################################################################
