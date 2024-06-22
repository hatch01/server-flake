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
  "gitlab/databasePasswordFile.age".publicKeys = all;
  "gitlab/initialRootPasswordFile.age".publicKeys = all;
  "gitlab/secretFile.age".publicKeys = all;
  "gitlab/otpFile.age".publicKeys = all;
  "gitlab/dbFile.age".publicKeys = all;
  "gitlab/jwsFile.age".publicKeys = all;
  "selfSignedCert.age".publicKeys = all;
  "selfSignedCertKey.age".publicKeys = all;
  "smtpPassword.age".publicKeys = all;

  "autheliaStorageKey.age".publicKeys = all;
  "autheliaJwtKey.age".publicKeys = all;
  "autheliaAuthBackend.age".publicKeys = all;
  "autheliaOauth2PrivateKey.age".publicKeys = all;
}
