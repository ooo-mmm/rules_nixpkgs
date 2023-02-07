load(
    "@rules_nixpkgs_core//:nixpkgs.bzl",
    "nixpkgs_git_repository",
    "nixpkgs_local_repository",
    "nixpkgs_package",
)

def nixpkgs_repositories(*, bzlmod):
    nixpkgs_local_repository(
        name = "nixpkgs",
        # TODO[AH] Remove these files from
        # rules_nixpkgs_core.
        nix_file = "//:nixpkgs.nix",
        nix_file_deps = ["//:flake.lock"],
    )

    nixpkgs_git_repository(
        name = "remote_nixpkgs",
        remote = "https://github.com/NixOS/nixpkgs",
        revision = "22.05",
        sha256 = "0f8c25433a6611fa5664797cd049c80faefec91575718794c701f3b033f2db01",
    )

    # same as @nixpkgs but using the `nix_file_content` parameter
    nixpkgs_local_repository(
        name = "nixpkgs_content",
        nix_file_content = "import ./nixpkgs.nix",
        nix_file_deps = [
            "//:nixpkgs.nix",
            "//:flake.lock",
        ],
    )

    nixpkgs_package(
        name = "hello",
        # Deliberately not repository, to test whether repositories works.
        repositories = {"nixpkgs": "@nixpkgs"},
    )

    nixpkgs_package(
        name = "expr-test",
        nix_file_content = "let pkgs = import <nixpkgs> { config = {}; overlays = []; }; in pkgs.hello",
        nix_file_deps = ["//:flake.lock"],
        # Deliberately not @nixpkgs, to test whether explict file works.
        repositories = {"nixpkgs": "//:nixpkgs.nix"},
    )

    nixpkgs_package(
        name = "attribute-test",
        attribute_path = "hello",
        repository = "@nixpkgs",
    )

    nixpkgs_package(
        name = "expr-attribute-test",
        attribute_path = "hello",
        nix_file_content = "import <nixpkgs> { config = {}; overlays = []; }",
        repository = "@nixpkgs",
    )

    nixpkgs_package(
        name = "nix-file-test",
        attribute_path = "hello",
        nix_file = "//tests:nixpkgs.nix",
        repository = "@nixpkgs",
    )

    nixpkgs_package(
        name = "nix-file-deps-test",
        nix_file = "//tests:hello.nix",
        nix_file_deps = ["//tests:pkgname.nix"],
        repository = "@nixpkgs",
    )

    nixpkgs_package(
        name = "nixpkgs-git-repository-test",
        attribute_path = "hello",
        repositories = {"nixpkgs": "@remote_nixpkgs"},
    )

    nixpkgs_package(
        name = "nixpkgs-local-repository-test",
        nix_file_content = "with import <nixpkgs> {}; hello",
        repositories = {"nixpkgs": "@nixpkgs_content"},
    )

    nixpkgs_package(
        name = "relative-imports",
        attribute_path = "hello",
        nix_file = "//tests:relative_imports.nix",
        nix_file_deps = [
            "//:flake.lock",
            "//:nixpkgs.nix",
            "//tests:relative_imports/nixpkgs.nix",
        ],
        repository = "@nixpkgs",
    )

    nixpkgs_package(
        name = "output-filegroup-test",
        nix_file = "//tests:output.nix",
        repository = "@nixpkgs",
    )

    nixpkgs_package(
        name = "output-filegroup-manual-test",
        build_file_content = """
package(default_visibility = [ "//visibility:public" ])
filegroup(
    name = "manual-filegroup",
    srcs = glob(["hi-i-exist", "hi-i-exist-too", "bin/*"]),
)
    """,
        nix_file = "//tests:output.nix",
        repository = "@nixpkgs",
    )

    nixpkgs_package(
        name = "nixpkgs_location_expansion_test",
        build_file_content = "exports_files(glob(['out/**']))",
        nix_file = "//tests:location_expansion.nix",
        nix_file_deps = [
            "//tests:location_expansion/test_file",
            "@nixpkgs_location_expansion_test_file//:test_file",
        ],
        nixopts = [
            "--arg",
            "local_file",
            "$(location //tests:location_expansion/test_file)",
            "--arg",
            "external_file",
            # TODO[AH] Support location expansion in bzlmod mode.
            #   When evaluating location expansion in the repository rule
            #   context, we only have access to the stringly representation
            #   entered by the user, and the mangled label representations of
            #   `nix_file_deps`. The Starlark API offers no way to access the
            #   unmangled module name. So, we need to provide a mapping from
            #   user defined label strings to mangled labels.
            './$${"$(location @@nixpkgs_location_expansion_test_file~override//:test_file)"}'
            if bzlmod else
            "$(location @nixpkgs_location_expansion_test_file//:test_file)" ,
        ],
        repository = "@remote_nixpkgs",
    )
