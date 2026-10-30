# miscellany
Miscellaneous small projects that haven't earned their separate repos

## `run-fhs`
A nix derivation for a minimal FHS environment, based on `steam-run`.

Originally assembled to run Silksong without enabling 32-bit components.

## `easyroam_iwd`
A script for creating IWD provisioning file `/var/lib/iwd/eduroam.8021x` from 
an easyroam profile PKCS12 bundle (`.p12` file).

Based on various other scripts. (see the comments in the script)

P.S. I'm embedding everything in the IWD provisioning file, with an unencrypted
private key and everything. Uni Greifswald's script stores the passphrase, key
and certificates separately, which makes it less painful if IWD decides to clean
up `/var/lib/iwd/`, and is probably more secure.
