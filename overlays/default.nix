inputs: final: _prev: {
  prs = import inputs.authelia {
    system = final.system;
  };
  only = import inputs.onlyoffice {
    system = final.system;
    config.allowUnfree = true;
  };
}
