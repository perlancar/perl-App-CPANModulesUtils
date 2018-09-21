package App::CPANModulesUtils;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

our %SPEC;

$SPEC{gen_acme_cpanmodules_module_from_acme_cpanlists_list} = {
    v => 1.1,
    summary => 'Generate an Acme::CPANModules module file from an Acme::CPANLists module list',
    args => {
        input_module => {
            schema => 'perl::modname*',
            req => 1,
            description => <<'_',

"Acme::CPANLists::" will be prepended if module name does not begin with it.

_
        },
        input_list_index => {
            schema => 'nonnegint*',
            cmdline_aliases => {n=>{}},
            description => <<'_',

Required if the Acme::CPANLists module contains more than one module list.

_
        },
        output_module => {
            schema => 'perl::modname*',
            description => <<'_',

"Acme::CPANModules::" will be prepended if module name does not begin with it.

Will default to the Acme::CPANLists module name, with CPANLists replaced by
CPANModules.

_
        },
        output_file => {
            schema => 'filename*',
            description => <<'_',

will default to "lib/Acme/CPANModules/<YourModuleName>.pm

_
            #cmdline_aliases => {o=>{}},
        },
        overwrite => {
            cmdline_aliases => {O=>{}},
        },
    },
};
sub gen_acme_cpanmodules_module_from_acme_cpanlists_list {
    require Data::Dump;
    require File::Path;
    require File::Slurper;

    my %args = @_;

    my $input_module = $args{input_module};
    $input_module = "Acme::CPANLists::$input_module"
        unless $input_module =~ /\AAcme::CPANLists::/;

    my $output_module = $args{output_module} // do {
        (my $val = $input_module) =~ s/CPANLists/CPANModules/;
        $val;
    };
    $output_module = "Acme::CPANModules::$input_module"
        unless $input_module =~ /\AAcme::CPANModules::/;

    my $output_file = $args{output_file} // do {
        (my $val = "lib/$output_module.pm") =~ s!::!/!g;
    };

    my $idx = $args{input_list_index};
    (my $input_module_pm = "$input_module.pm") =~ s!::!/!g;
    require $input_module_pm;
    my $module_lists = \@{"$input_module_pm\::Module_Lists"};
    @$module_lists or return [412, "$input_module doesn't contain any module list"];
    if (@$module_lists > 1) {
        defined $idx or return [400, "Please specify input_list_index because $input_module contains more than one module list"];
        $idx < @$module_lists or return [400, "There is no module list #$idx in $input_module"];
    }
    $idx //= 0;

    if (-f $output_file) {
        !$args{overwrite} or return [412, "Output file $output_file already exists, specify another file or --overwrite"];
    } else {
        if ($input_file =~ m!/.!) {
            (my $dir = $input_file) =~ s!(.+)/.+!$1!;
            File::Path::make_path($dir);
        }
    }

    my $output = join(
        "",

        "package $output_module;\n",
        "\n",

        "# DATE\n",
        "# VERSION\n",
        "\n",

        "our \$LIST = ", Data::Dump::dump($module_lists->[$idx]), ";\n",
        "\n",

        "# ABSTRACT: ", ($module_lists->[$idx]{summary} // "(no summary)"), "\n",
        "\n",
    );

    File::Slurper::write_text($output, $output_file);
    [200];
}


1;
#ABSTRACT: Command-line utilities related to Acme::CPANModules

=head1 SYNOPSIS


=head1 DESCRIPTION

This distribution includes the following command-line utilities related to
L<Acme::CPANModules>:

# INSERT_EXECS_LIST


=head1 SEE ALSO

L<Acme::CPANModules>
