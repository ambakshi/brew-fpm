# brew-fpm

This tap is based on [timsutton/brew-pkg](https://github.com/timsutton/brew-pkg)
brew-fpm is a Homebrew external command that builds an OS installer package from a formula using [Jordan Sissel's excellent FPM](https://github.com/jordansissel/fpm)

The formula must first already be installed on the system via `brew install <pkg>` before you can `brew fpm <package>`.

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

## Use docker

The included `Makefile` builds an EL7 image with `linuxbrew`, `brew` and `brew-fpm`

```
make image
make run
make exec
```

This gives you a persistent `$HOME` inside the container. After the `make exec` you'll be inside the EL7 container. Do a
`brew install curl` and `brew fpm curl` to get a curl el7 rpm, linked statically. The first time the build will take a
bit longer, because many low level dependencies (such as `autoconf`, `m4`, etc) are missing. Subsequent packages build
much faster. Your host directory is mounted to `/host`. Run the `brew fpm` command in that directory to have your packages
available on the host. You can use this technique to build other containers for EL6, Ubuntu, etc. Patches welcome :)

## Issues

* I've never written any Ruby in my life. This is cobbled together from timsutton/brew-pkg, which does pkg file creating. Since FPM can do this, is it strict necessary?
* All packages use a prefix of /usr/local, insead of the tradition /usr. Existing OS packages are correctly replaced/updated, but the location isn't what one would expect.
* To properly build rpm's from an Ubuntu host (or visa versa) you need to do it on a EL host, especially for EL6 where libc version is different. I'm doing it with docker containers locally. So while you can specify --rpm on a Debian host, the package may not come up too healthy :)

## License

brew-fpm is [MIT-licensed](https://github.com/ambakshi/brew-fpm/blob/master/LICENSE.md).
