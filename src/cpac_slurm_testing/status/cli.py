"""CLI tooling for C-PAC SLURM testing."""
from argparse import ArgumentParser, Namespace, RawDescriptionHelpFormatter
from logging import basicConfig, getLogger, INFO
import os

from cpac_slurm_testing import __version__
from cpac_slurm_testing.launch import launch, LaunchParameters
from cpac_slurm_testing.status._global import LOG_FORMAT
from cpac_slurm_testing.status.status import RunStatus, TestingPaths, TotalStatus

LOGGER = getLogger(name=__name__)
basicConfig(format=LOG_FORMAT, level=INFO)


def _argstring(arg: str) -> list[str]:
    """Return all versions of an arg with dashes or underscores."""
    return list(
        {
            f"--{argstr}"
            for argstr in [arg, arg.replace("-", "_"), arg.replace("_", "-")]
        }
    )


def check(status: TotalStatus, args: Namespace) -> None:
    """Check a run's status."""
    status[
        (
            args.data_source,
            args.preconfig,
            args.subject,
        )
    ].job_status
    LOGGER.info(status)


def check_all(status: TotalStatus) -> None:
    """Check all runs' statuses."""
    for run in status.runs.values():
        run.job_status
    LOGGER.info(status)


def _env_varname(arg: str) -> str:
    """Return an environment argument name given a CLI argument name."""
    return f"_CPAC_STATUS_{arg.upper().replace('-', '_')}"


class SlurmTestingNamespace(Namespace):
    """Namespace, but with additional ``_env_fallback`` method.

    Also updates wd to an absolute path and sets up logging.
    """

    def _env_fallback(self: Namespace, arg: str) -> str | bool:
        """Get an argument value from ENV if not passed as an argument."""
        try:
            value = getattr(self, arg)
        except AttributeError:
            if arg == "dry_run":
                return False
            value = None
        if value is None:
            env_var = _env_varname(arg)
            try:
                return os.environ[env_var]
            except LookupError:
                msg = (
                    f"'{arg}' was not provided. Either set '--{arg}' in the run command"
                    f" or ${env_var} in the environment."
                )
                raise LookupError(msg)
        return value

    def __init__(self, original: Namespace) -> None:
        """Initialize Namespace."""
        super().__init__(
            **{
                key: value if value else self._env_fallback(key)
                for key, value in vars(original).items()
            }
        )
        if not hasattr(self, "dry_run"):
            self.dry_run: bool = False
            """Skip actually running commands?"""
        self.testing_paths = TestingPaths(self.wd)


def _parser_arg_helpstring(arg: str) -> str:
    """Return a string describing the optional environment variable."""
    return f"falls back on ${_env_varname(arg)} if this option is not set"


def _parser() -> tuple[ArgumentParser, dict[str, ArgumentParser]]:
    """Create a parser to parse commandline args."""
    base_parser = ArgumentParser(add_help=False)
    base_parser.add_argument(
        "--working_directory",
        "--workdir",
        "--wd",
        dest="wd",
        help="specify working directory. falls back on $REGTEST_LOG_DIR if not "
        "provided, and uses the actual current working directory if that environment "
        "variable is not set",
    )
    base_parser.add_argument(
        "--dry-run", action="store_true", help="If set, jobs will not be run."
    )
    parser = ArgumentParser(
        prog="cpac-slurm-status",
        description=__doc__,
        formatter_class=RawDescriptionHelpFormatter,
        parents=[base_parser],
    )
    update_parser = ArgumentParser(add_help=False)
    for arg in ["data-source", "preconfig", "subject"]:
        update_parser.add_argument(*_argstring(arg), help=_parser_arg_helpstring(arg))
    subparsers = parser.add_subparsers(dest="command")
    for command, description in {
        "add": "add a run in a pending status",
        "check": "check a run's status in SLURM",
        "finalize": "finalize a run (success, failure or error)",
    }.items():
        subparsers.add_parser(
            command,
            description=description,
            help=description,
            parents=[base_parser, update_parser],
        )
    _description = "check all runs' statuses in SLURM"
    subparsers.add_parser(
        "check-all", description=_description, help=_description, parents=[base_parser]
    )
    _description = "launch a regression test"
    subparsers.add_parser(
        "launch", description=_description, help=_description, parents=[base_parser]
    )
    del _description
    for arg in LaunchParameters.keys(except_for=["dry_run", "testing_paths"]):
        subparsers.choices["launch"].add_argument(
            *_argstring(arg), help=_parser_arg_helpstring(arg)
        )
    parser.add_argument(
        "--version", "-v", action="version", version=f"%(prog)s {__version__}"
    )
    subparsers.choices["add"].set_defaults(status="pending")
    subparsers.choices["finalize"].add_argument(
        "--status",
        choices=["success", "failure", "error"],
        help=_parser_arg_helpstring("status"),
    )
    subparsers.choices = dict(sorted(subparsers.choices.items()))

    return parser, subparsers.choices


def update(status: TotalStatus, args: Namespace) -> None:
    """Update a run."""
    run = RunStatus(
        args.data_source,
        args.preconfig,
        args.subject,
        getattr(args, "status"),
        _total=status,
        dry_run=status.dry_run,
    )
    run.launch("lite_run")
    status += run


def main() -> None:
    """Run the script from the commandline."""
    # Parse the arguments
    parser, _subparsers = _parser()
    args = SlurmTestingNamespace(parser.parse_args())
    # Update the status
    if args.command == "launch":
        launch(
            LaunchParameters(
                **{key: getattr(args, key) for key in LaunchParameters.keys()}
            )
        )
    else:
        status = TotalStatus(testing_paths=args.testing_paths, dry_run=args.dry_run)
        if args.command in ["add", "finalize"]:
            update(status, args)
        elif args.command == "check":
            check(status, args)
        elif args.command == "check-all":
            check_all(status)


if __name__ == "__main__":
    main()
