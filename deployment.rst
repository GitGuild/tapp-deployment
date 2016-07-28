=================================
De Shared Wallet Deployment Guide
=================================

This process will take you from a basic Linux installation to a fully
functional DeSW server. It is recommended to follow the instructions exactly to
ensure success, but experienced sysadmins will be able to modify certain
steps to best fit their own environments and preferences.

It is suggested to read the whole guide to get an overview before starting.

.. contents::

Build and Install the DeSW Stack
================================

Prepare the Build Environment
-----------------------------

This section assumes a Debian system with Python 2.7 installed. As we will be
building all but the most common dependencies ourselves, it should be readily
adapted to any reasonably similar OS.

For fetching and verifying code::

    # apt-get install git curl gnupg

For ``libsecp256k1``::

    # apt-get install automake libtool pkg-config make

For Python ``cffi``::

    # apt-get install libffi-dev python-dev

For Python package building and deployment::

    # apt-get install python-setuptools

For security and reliability we will not be deploying Python code straight from
PyPI as is many developers' habit. Instead we will proceed in separate steps to
download and verify sources, build a local repository of binary packages
("eggs"), and install from there. The astute sysadmin will note that this
enables one to avoid running DeSW or dependency code as root, preserve sources
of the full dependency tree in your own repository for safe keeping, build on a
separate system if desired and so on.

To enforce this policy, configure ``easy_install`` to use the local repository
and forbid it from downloading from the Internet::

    # mkdir -p /usr/local/pypi
    # cat > /usr/lib/python2.7/distutils/distutils.cfg <<EOF
    [easy_install]
    allow_hosts = ''
    index_url = /usr/local/pypi
    EOF

You may need to adjust the ``distutils.cfg`` location above for your system; it
must be in the system's ``distutils`` package directory. If you're unsure where
this is::

    # dirname `python -c "import distutils; print distutils.__file__"`

Create an unprivileged user for building the code::

    # useradd -m -s /bin/bash build
    # su - build

Get the Code
------------

DeSW, the ``secp256k1`` C library, and deployment scripts currently need to be
fetched from git::

    $ git clone https://github.com/GitGuild/tapp-deployment.git
    $ git clone https://github.com/GitGuild/desw.git
    $ git clone https://github.com/GitGuild/desw-bitcoin.git
    $ git clone https://github.com/GitGuild/desw-dash.git
    $ git clone https://github.com/GitGuild/sqlalchemy-models.git
    $ git clone https://github.com/bitcoin-core/secp256k1.git

The full set of Python dependencies can be fetched from PyPI with aid of a
simple download script. Review its contents, adapt as necessary, and run::

    $ sh tapp-deployment/download.sh

To verify the downloads you'll need the manifest file and the PGP key used to
sign it. The fingerprint is ``2599 9E50 95BA 9A2E 1CE6  305E A890 2A7C ACFD
13B0``; it can be obtained from http://www.welshcomputing.com/pgp.html, or
directly::

    $ curl -O http://www.welshcomputing.com/jacob-welsh.asc | gpg --import

Or from keyservers::

    $ gpg --recv-keys ACFD13B0

Verify the manifest signature::

    $ gpg --verify tapp-deployment/manifest.welshjf.asc tapp-deployment/manifest

You should see "Good signature". Take due note of the WARNING you'll receive if
you don't have a trust path to the key. Then use the manifest to verify
checksums::

    $ sha512sum -c tapp-deployment/manifest

Build and Install libsecp256k1
------------------------------

The ``libsecp256k1`` C library (used for signing in Bitcoin Core 0.10+) is
required by ``bitjws``. From the README:

    This library is a work in progress and is being used to research best
    practices. Use at your own risk.

It does not yet have a stable API so we need to use a specific git commit (you
can confirm the SHA1 from a comment in the signed manifest)::

    $ cd secp256k1
    $ git checkout d7eb1ae96dfe9d497a26b3e7ff8b6f58e61e400a
    $ ./autogen.sh
    $ ./configure --without-asm --without-bignum --enable-module-recovery
    $ make
    $ make install DESTDIR=$PWD/staging
    $ tar czf secp256k1-built.tar.gz --owner root --group root -C staging usr

Configure options explained:

* ``--without-asm`` (optional): this disables assembly optimizations; we're not
  verifying the whole blockchain here so legible code should count more than
  shaving cycles.
* ``--without-bignum`` (optional): the library can use either an internal or
  more efficient GMP implementation of the modular inverse operation. This flag
  avoids a dependency by explicitly disabling GMP which would otherwise be
  autodetected. To explicitly enable it, use ``--with-bignum=gmp``.
* ``--enable-module-recovery`` (required): this enables functions to derive the
  ECDSA public key that signed a message from the message and signature.
  Required by ``bitjws``.

As root, install and refresh the dynamic linker cache::

    $ exit
    # tar xf /home/build/secp256k1/secp256k1-built.tar.gz -C /
    # ldconfig
    # su - build

Build Python Packages
---------------------

The build process for the Python packages (DeSW, Gunicorn application server,
and dependencies) is mostly straightforward, but there are a lot of them, and a
few complications, so a simple build script has been prepared. Read it to see
what it does, then run::

    $ sh tapp-deployment/build.sh

For the time being, DeSW itself, data models, and plugins still need to be
built from git::

    $ cd desw
    $ git checkout <commit TBA>
    $ python setup.py bdist_egg
    $ cd ..

    $ cd desw-bitcoin
    $ git checkout <commit TBA>
    $ python setup.py bdist_egg
    $ cd ..

    $ cd desw-dash
    $ git checkout <commit TBA>
    $ python setup.py bdist_egg
    $ cd ..

    $ cd sqlalchemy-models
    $ git checkout <commit TBA>
    $ python setup.py bdist_egg
    $ cd ..

Install Python Packages
-----------------------

As root, copy the built packages to the local repository (avoid ``mv`` as that
would preserve ownership)::

    $ exit
    # cp /home/build/pypi/eggs/*.egg \
        /home/build/desw*/dist/*.egg \
        /home/build/sqlalchemy-models/dist/*.egg \
        /usr/local/pypi/

Now install the works::

    # easy_install desw desw_bitcoin desw_dash sqlalchemy_login_models gunicorn

There is no ``easy_uninstall`` so take note of where it writes files (probably
under ``/usr/local/lib/pythonX.Y`` and ``/usr/local/bin``). You can use a
virtualenv if you prefer, but you'll need to edit its local ``distutils.cfg``
as above, after creating the environment but before installing packages.

Note that ``jsonschema`` uses a fancy version-dependent requirement
specification mechanism that doesn't work on older setuptools. Thus you may
still need to ``easy_install`` either ``repoze.lru`` for Python 2.6 (UNTESTED)
or ``functools32`` for Python 2.7. The symptom would be DeSW failing to load
with an ``ImportError`` on one of those packages.

Configure DeSW
==============

Configuration
-------------

Create an unprivileged user to run the application::

    # useradd -Ur desw

Create a directory for the application's Python log messages::

    # mkdir /var/log/desw
    # chown desw /var/log/desw

Create and secure a configuration file, for example::

    # cp /home/build/example_cfg.ini /etc/desw.cfg
    # chgrp desw /etc/desw.cfg
    # chmod 640 /etc/desw.cfg

Edit this to configure the database, logging and plugins as needed. For each
plugin section, e.g. ``[somecoin]``, you must have the corresponding
``desw_somecoin`` package installed. Each plugin, including ``internal``,
requires FEE and CURRENCIES (codes of up to four characters, as a JSON list),
e.g.::

    [bitcoin]
    FEE: 10000
    CURRENCIES: ["BTC"]

    [internal]
    FEE: 0
    CURRENCIES: []

An example for connecting to the ``desw`` database in PostgreSQL through its
local Unix-domain socket with peer authentication, using the ``psycopg2``
connector::

    [db]
    SA_ENGINE_URI: postgresql+psycopg2://@/desw

Generating the private and public key pair for the ``[bitjws]`` section to
authenticate your service is a bit clunky at the moment. **DO NOT USE THE
EXAMPLE KEY IN PRODUCTION!** From a Python prompt::

    >>> from bitjws import *
    >>> raw = gen_privatekey()
    >>> print privkey_to_wif(raw)
    >>> print pubkey_to_addr(PrivateKey(raw).pubkey.serialize())

It is assumed that you already have your desired currency node software
configured; set its RPCURL in the corresponding plugin section.

Service Management
------------------

You'll likely want to use some supervisor framework to handle process
daemonization, logging and lifecycle. The following example will get you
started with runit_ on Debian. Reading the documentation, particularly
``sv(8)``, is recommended if you're not familiar with it. Other options include
s6_, supervisord_, even upstart or systemd if you must, and so on.
::

    # apt-get install runit
    # mkdir -p /etc/sv/desw/log

Create the run script ``/etc/sv/desw/run``. This example shows
production-oriented security settings::

    #!/bin/sh
    export DESW_CONFIG_FILE=/etc/desw.cfg
    exec chpst -u desw:desw /usr/bin/python2.7 -ERs /usr/local/bin/gunicorn \
            desw.server:app \
            --bind 127.0.0.1:8000 \
            --access-logfile /var/log/desw/access.log \
            --workers 4 2>&1

To capture gunicorn's logs from stdout/stderr, create a run script for the
logging service ``/etc/sv/desw/log/run``::

    #!/bin/sh
    exec svlogd -tt .

Enable the service::

    # chmod +x /etc/sv/desw/run /etc/sv/desw/log/run
    # ln -s /etc/sv/desw /etc/service/

If all is well, the service will start up automatically and you'll see some
gunicorn messages in ``/etc/sv/desw/log/current``.

You can send SIGHUP to have gunicorn do a graceful reload of the code/config
while allowing active workers to complete::

    # sv hup desw

Or send SIGTERM to gracefully exit and have the whole service restarted by
``runsv(8)``::

    # sv term desw

To send SIGTERM and stay down (at least until next boot)::

    # sv down desw

.. _runit: http://smarden.org/runit/
.. _s6: http://skarnet.org/software/s6/
.. _supervisord: http://supervisord.org/

Configure Front End Proxy
-------------------------

TODO: any nginx notes
