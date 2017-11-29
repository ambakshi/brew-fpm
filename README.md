# brew-fpm

This tap is based on [timsutton/brew-pkg](https://github.com/timsutton/brew-pkg)
brew-fpm is a Homebrew external command that builds an OS X installer package from a formula. The formula must first already be installed on the system.

## Usage

Assuming nginx is already installed:

`brew fpm nginx`
<code><pre>==> Creating package staging root using Homebrew prefix /usr/local
==> Staging formula nginx
==> Building package nginx-1.2.6.deb</pre></code>

It can also automatically include the formula's dependencies:

`brew fpm --with-deps --without-kegs ffmpeg`
<code><pre>==> Creating package staging root using Homebrew prefix /usr/local
==> Staging formula ffmpeg
==> Staging formula texi2html
==> Staging formula yasm
==> Staging formula x264
==> Staging formula faac
==> Staging formula lame
==> Staging formula xvid
==> Building package ffmpeg-1.1.deb</pre></code>

By default behaviour brew fpm include all package kegs located in /usr/local/Cellar/packagename. If you need to exclude it, specify option --without-kegs

## Installing it

brew-fpm is available from my [formulae tap](https://github.com/ambakshi/homebrew-formulae). Add the tap:

`brew tap ambakshi/formulae`

Then install as any other formula:

`brew install brew-fpm`

## Extras

You can set any custom fpm argument with the `--fpm-arg` option which is just literally passed through to the `fpm` command.
For more information refer to `man fpm`.

## License

brew-fpm is [MIT-licensed](https://github.com/ambakshi/brew-fpm/blob/master/LICENSE.md).
