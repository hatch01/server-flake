inputs: final: _prev: {
  homepage-dashboard = _prev.homepage-dashboard.overrideAttrs (oldAttrs: rec {
    pname = "homepage";
    version = "0.9.9";
    src = final.fetchFromGitHub {
      owner = "gethomepage";
      repo = "homepage";
      rev = "v${version}";
      hash = "sha256-jUKXAqq6Oj8CmOuBUlsf0zDIcK+3MX/czzNDmakN9VM=";
    };
    npmDepsHash = "sha256-YjcF8FkURnTurcJ0Iq0ghv/bhu5sFA860jXrn3TkRds=";
    npmDeps = final.fetchNpmDeps {
      inherit src;
      name = "${pname}-${version}-npm-deps";
      hash = npmDepsHash;
    };
  });
}
