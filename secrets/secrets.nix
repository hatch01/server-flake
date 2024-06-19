let
  eymeric = "age17w7zsvgvdfr7tdkz9uwy2jhmjlt2273ktu6wtt976782nen0sfkql94ez6";

  all = [eymeric];
in {
  "userPassword.age".publicKeys = all;
  "githubToken.age".publicKeys = all;
  "nextcloudAdmin.age".publicKeys = all;
  "nextcloudSecretFile.age".publicKeys = all;
  "onlyofficeKey.age".publicKeys = all;
  "dendriteKey.age".publicKeys = all;
  "homepage.age".publicKeys = all;
  "selfSignedCert.age".publicKeys = all;
  "selfSignedCertKey.age".publicKeys = all;

  "autheliaStorageKey.age".publicKeys = all;
  "autheliaJwtKey.age".publicKeys = all;
  "autheliaAuthBackend.age".publicKeys = all;
  "autheliaOauth2PrivateKey.age".publicKeys = all;
  "autheliaSmtpPassword.age".publicKeys = all;
}
