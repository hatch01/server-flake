inputs: final: _prev: {
  prs = import inputs.authelia {
    system = final.system;
  };
}
